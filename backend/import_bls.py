"""Importiert den Bundeslebensmittelschlüssel (BLS 4.0, Max Rubner-Institut) in die Tabelle reference_foods.

    python3 import_bls.py /pfad/BLS_4_0_Daten_2025_DE.xlsx

Quelle: Max Rubner-Institut (2025): Bundeslebensmittelschlüssel (BLS), Version 4.0 — Deutsche Nährstoffdatenbank.
Karlsruhe. DOI: 10.25826/Data20251217-134202-0 — kostenfrei, ausdrücklich auch für App-/Softwareentwicklung.

Schreibt AUSSCHLIESSLICH in reference_foods (anlegen bzw. per BLS-Code aktualisieren) — food_items, daily_logs
und alle anderen Nutzertabellen werden nicht angefasst. Liest die xlsx ohne Zusatzpakete (zipfile + XML).
Werte je 100 g essbarer Anteil; fehlende Werte bleiben leer (BLS unterscheidet fehlend von 0).
"""
import re
import sys
import zipfile
import xml.etree.ElementTree as ET

from sqlalchemy.dialects.postgresql import insert

from database import engine, SessionLocal
import models

NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
# BLS-Komponentencode -> Spalte in reference_foods
FELDER = {"ENERCC": "calories_per_100g", "PROT625": "protein_per_100g", "CHO": "carbs_per_100g",
          "FAT": "fat_per_100g", "FIBT": "fiber_per_100g"}


def _spalte(ref: str) -> int:
    n = 0
    for ch in re.match(r"[A-Z]+", ref).group(0):
        n = n * 26 + ord(ch) - 64
    return n - 1


def xlsx_zeilen(pfad: str):
    with zipfile.ZipFile(pfad) as z:
        texte = []
        if "xl/sharedStrings.xml" in z.namelist():
            for si in ET.fromstring(z.read("xl/sharedStrings.xml")).findall("m:si", NS):
                texte.append("".join(t.text or "" for t in si.iter(f"{{{NS['m']}}}t")))
        blatt = sorted(n for n in z.namelist() if n.startswith("xl/worksheets/sheet"))[0]
        for row in ET.fromstring(z.read(blatt)).iter(f"{{{NS['m']}}}row"):
            werte = {}
            for c in row.findall("m:c", NS):
                v = c.find("m:v", NS)
                if c.get("t") == "inlineStr":
                    wert = "".join(t.text or "" for t in c.iter(f"{{{NS['m']}}}t"))
                elif v is None:
                    continue
                elif c.get("t") == "s":
                    wert = texte[int(v.text)]
                else:
                    wert = v.text
                werte[_spalte(c.get("r"))] = wert
            if werte:
                yield [werte.get(i) for i in range(max(werte) + 1)]


def _zahl(v):
    if v is None or str(v).strip() in ("", "-", "n.a.", "NA"):
        return None
    try:
        return round(float(str(v).replace(",", ".")), 2)
    except ValueError:
        return None


def main(pfad: str):
    zeilen = xlsx_zeilen(pfad)
    kopf = [str(k or "").strip() for k in next(zeilen)]
    # Wertspalte = "<CODE> Bezeichnung … [Einheit/100g]" (die Folgespalten "Datenherkunft"/"Referenz" haben keine Einheit)
    pos = {}
    for code, feld in FELDER.items():
        kandidaten = [i for i, k in enumerate(kopf) if k.startswith(code + " ") and "[" in k]
        if not kandidaten:
            sys.exit(f"Spalte {code} nicht gefunden — Dateiformat geändert? Kopf: {kopf[:8]} …")
        pos[feld] = kandidaten[0]
    print("Spalten:", {f: kopf[i] for f, i in pos.items()})

    models.Base.metadata.create_all(bind=engine, tables=[models.ReferenceFood.__table__])
    daten = []
    for z in zeilen:
        code, name = (z[0] if len(z) > 0 else None), (z[1] if len(z) > 1 else None)
        if not code or not name:
            continue
        eintrag = {"code": str(code).strip()[:16], "name": str(name).strip()[:255], "source": "BLS 4.0"}
        for feld, i in pos.items():
            eintrag[feld] = _zahl(z[i] if i < len(z) else None)
        daten.append(eintrag)
    if len(daten) < 1000:
        sys.exit(f"Nur {len(daten)} Lebensmittel gelesen — Abbruch (erwartet ~7 140)")

    db = SessionLocal()
    try:
        tabelle = models.ReferenceFood.__table__
        for i in range(0, len(daten), 500):
            stmt = insert(tabelle).values(daten[i:i + 500])
            stmt = stmt.on_conflict_do_update(index_elements=["code"], set_={
                k: stmt.excluded[k] for k in ("name", *FELDER.values(), "source")})
            db.execute(stmt)
        db.commit()
        print(f"{len(daten)} BLS-Lebensmittel importiert, reference_foods hat jetzt "
              f"{db.query(models.ReferenceFood).count()} Einträge")
    finally:
        db.close()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])

"""Converts the Bundeslebensmittelschlüssel (BLS 4.0, Max Rubner-Institut) into assets/bls.tsv.

    python3 tool/bls_to_tsv.py /path/BLS_4_0_Daten_2025_DE.xlsx > assets/bls.tsv

Source: Max Rubner-Institut (2025): Bundeslebensmittelschlüssel (BLS), Version 4.0 — Deutsche Nährstoffdatenbank.
Karlsruhe. DOI: 10.25826/Data20251217-134202-0 — free of charge, explicitly also for app/software development
(download: https://blsdb.de/download).

Output: code, name, kcal, protein, carbs, fat, fiber per 100 g edible part; empty = value missing in the BLS
(the BLS distinguishes missing from 0). Reads the xlsx with the standard library only.
"""
import re
import sys
import zipfile
import xml.etree.ElementTree as ET

NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
# BLS component code, in output column order
FELDER = ["ENERCC", "PROT625", "CHO", "FAT", "FIBT"]


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


def _zahl(v) -> str:
    if v is None or str(v).strip() in ("", "-", "n.a.", "NA"):
        return ""
    try:
        return f"{round(float(str(v).replace(',', '.')), 2):g}"
    except ValueError:
        return ""


def main(pfad: str):
    zeilen = xlsx_zeilen(pfad)
    kopf = [str(k or "").strip() for k in next(zeilen)]
    # value column = "<CODE> name … [unit/100g]" (the following "Datenherkunft"/"Referenz" columns have no unit)
    pos = []
    for code in FELDER:
        kandidaten = [i for i, k in enumerate(kopf) if k.startswith(code + " ") and "[" in k]
        if not kandidaten:
            sys.exit(f"column {code} not found — file format changed? head: {kopf[:8]} …")
        pos.append(kandidaten[0])
    n = 0
    for z in zeilen:
        code, name = (z[0] if len(z) > 0 else None), (z[1] if len(z) > 1 else None)
        if not code or not name:
            continue
        name = re.sub(r"\s+", " ", str(name)).strip()
        werte = [_zahl(z[i] if i < len(z) else None) for i in pos]
        sys.stdout.write("\t".join([str(code).strip(), name, *werte]) + "\n")
        n += 1
    if n < 1000:
        sys.exit(f"only {n} foods read — aborting (expected ~7 140)")
    print(f"{n} BLS foods", file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])

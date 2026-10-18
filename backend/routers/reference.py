"""Nährwert-Nachschlagen außerhalb der eigenen Lebensmittel:

* /api/reference-foods  — Bundeslebensmittelschlüssel BLS 4.0 (Max Rubner-Institut, kostenfrei auch für Apps),
                           lokal in der Tabelle reference_foods (befüllt von import_bls.py). Grundlebensmittel wie
                           "Rind, Filet, roh" oder "Vollmilch 3,5 % Fett".
* /api/online-foods     — Live-Textsuche bei Open Food Facts (Markenprodukte), wie schon der Barcode-Scan.

Nutzerdaten werden hier nie geändert oder gelöscht: Übernehmen legt höchstens eine NEUE Zeile in food_items an
(bzw. verwendet die eigene, früher übernommene Kopie wieder).
"""
import re
import time
import logging
from typing import List, Optional

import httpx
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from database import get_db
import models, schemas, auth

logger = logging.getLogger("macrobandit")

reference_router = APIRouter(prefix="/api/reference-foods", tags=["reference-foods"])
online_router = APIRouter(prefix="/api/online-foods", tags=["online-foods"])

BLS_MARKE = "BLS 4.0"

# ── Suche im BLS (im Speicher, 7 140 Einträge) ────────────────────────────────

_index = {"zeit": 0.0, "eintraege": []}      # [(row, normalisierter Name, Wörter)]
_INDEX_TTL = 600


def _norm(text: str) -> str:
    t = (text or "").lower().replace("ß", "ss")
    t = re.sub(r"(\d)\.(\d)", r"\1,\2", t)          # 3.5 -> 3,5 (BLS schreibt Dezimalkomma)
    t = re.sub(r"[^\wäöü,%]+", " ", t)
    t = re.sub(r"(?<!\d),|,(?!\d)", " ", t)          # Kommas nur zwischen Ziffern behalten
    return re.sub(r"\s+", " ", t).strip()


def _woerter(text: str) -> list:
    return [w for w in _norm(text).replace("%", " ").split() if w]


def _index_laden(db: Session) -> list:
    if time.time() - _index["zeit"] < _INDEX_TTL and _index["eintraege"]:
        return _index["eintraege"]
    rows = db.query(models.ReferenceFood).all()
    _index["eintraege"] = [(r, _norm(r.name), _woerter(r.name)) for r in rows]
    _index["zeit"] = time.time()
    return _index["eintraege"]


def _bewerten(token: str, name: str, woerter: list) -> float:
    """Wie gut passt ein Suchwort zum Lebensmittelnamen? 0 = gar nicht. Ohne Treffer wird die Einzahl
    probiert ("eier" -> "ei", "kartoffeln" -> "kartoffel"), mit etwas weniger Punkten."""
    wert = _bewerten_genau(token, name, woerter)
    if wert or token.isdigit():
        return wert
    for endung in ("ern", "en", "er", "n", "e", "s"):
        if token.endswith(endung) and len(token) - len(endung) >= 2:
            wert = _bewerten_genau(token[: -len(endung)], name, woerter)
            if wert:
                return wert * 0.8
    return 0.0


def _bewerten_genau(token: str, name: str, woerter: list) -> float:
    if token in woerter:
        return 3.0
    if any(w.startswith(token) for w in woerter):
        return 2.5
    if token in name:                                  # "milch" in "vollmilch"
        return 1.5
    # zusammengesetztes Suchwort: "rinderfilet" deckt "rind" + "filet" ab
    teile = [w for w in woerter if len(w) >= 4 and w in token]
    if teile:
        abgedeckt = sum(len(w) for w in teile) / len(token)
        return 1.0 + min(abgedeckt, 1.0)
    return 0.0


def bls_suchen(db: Session, q: str, limit: int = 15) -> list:
    tokens = _woerter(q)
    if not tokens:
        return []
    treffer = []
    for row, name, woerter in _index_laden(db):
        werte = [_bewerten(t, name, woerter) for t in tokens]
        passend = sum(1 for w in werte if w > 0)
        if passend == 0:
            continue
        # alle Suchwörter getroffen zuerst, dann Gesamtpunkte, dann kurze (allgemeine) Namen
        treffer.append(((passend == len(tokens)), sum(werte), -len(name), row))
    treffer.sort(key=lambda x: (x[0], x[1], x[2]), reverse=True)
    if any(t[0] for t in treffer):
        treffer = [t for t in treffer if t[0]]
    return [t[3] for t in treffer[:limit]]


def _ref_out(r: models.ReferenceFood) -> schemas.ReferenceFoodOut:
    return schemas.ReferenceFoodOut(
        code=r.code, name=r.name, brand=None,
        calories_per_100g=r.calories_per_100g, protein_per_100g=r.protein_per_100g,
        carbs_per_100g=r.carbs_per_100g, fat_per_100g=r.fat_per_100g, fiber_per_100g=r.fiber_per_100g,
        source=r.source or BLS_MARKE,
    )


@reference_router.get("", response_model=List[schemas.ReferenceFoodOut])
def search_reference(
    q: str = Query(..., min_length=2, max_length=100),
    limit: int = Query(15, ge=1, le=50),
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    return [_ref_out(r) for r in bls_suchen(db, q, limit)]


@reference_router.post("/{code}/use", response_model=schemas.FoodItemOut)
def use_reference(
    code: str,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    """BLS-Eintrag als eigenes Lebensmittel bereitstellen: vorhandene eigene Kopie wiederverwenden, sonst eine
    neue Zeile anlegen. Bestehende food_items werden nicht verändert."""
    ref = db.query(models.ReferenceFood).filter(models.ReferenceFood.code == code).first()
    if not ref:
        raise HTTPException(status_code=404, detail="BLS-Eintrag nicht gefunden")
    kopie = db.query(models.FoodItem).filter(
        models.FoodItem.user_id == current_user.id,
        models.FoodItem.brand == BLS_MARKE,
        models.FoodItem.name == ref.name,
    ).first()
    if not kopie:
        kopie = models.FoodItem(
            user_id=current_user.id, name=ref.name, brand=BLS_MARKE,
            calories_per_100g=ref.calories_per_100g, protein_per_100g=ref.protein_per_100g,
            carbs_per_100g=ref.carbs_per_100g, fat_per_100g=ref.fat_per_100g, fiber_per_100g=ref.fiber_per_100g,
        )
        db.add(kopie)
        db.commit()
        db.refresh(kopie)
    out = schemas.FoodItemOut.from_orm(kopie)
    out.use_count = 0
    return out


# ── Live-Suche Open Food Facts ────────────────────────────────────────────────
# OFF erlaubt für die Textsuche nur wenige Abfragen pro Minute — daher nur auf Knopfdruck aus dem Frontend
# und mit Zwischenspeicher (gleiche Suche 1 h nicht erneut abfragen).

# Neue OFF-Suche (search-a-licious); die alte cgi/search.pl ist häufig überlastet (503)
_OFF_URL = "https://search.openfoodfacts.org/search"
_OFF_FELDER = "code,product_name,product_name_de,brands,nutriments"
_off_cache = {}
_OFF_TTL = 3600


def _zahl(v) -> Optional[float]:
    try:
        return round(float(v), 2)
    except (TypeError, ValueError):
        return None


@online_router.get("", response_model=List[schemas.ReferenceFoodOut])
async def search_online(
    q: str = Query(..., min_length=2, max_length=100),
    current_user: models.User = Depends(auth.get_current_user),
):
    schluessel = _norm(q)
    if schluessel in _off_cache and time.time() - _off_cache[schluessel][0] < _OFF_TTL:
        return _off_cache[schluessel][1]
    params = {"q": q, "page_size": 25, "langs": "de", "fields": _OFF_FELDER}
    try:
        async with httpx.AsyncClient(timeout=10.0, headers={"User-Agent": "MacroBandit/1.0 (macrobandit.at)"}) as client:
            resp = await client.get(_OFF_URL, params=params)
        resp.raise_for_status()
        produkte = resp.json().get("hits", [])
    except Exception as e:
        logger.warning(f"Open Food Facts Suche fehlgeschlagen ({q!r}): {e}")
        raise HTTPException(status_code=502, detail="Online-Suche gerade nicht erreichbar")
    ergebnis = []
    for p in produkte:
        n = p.get("nutriments") or {}
        kcal = _zahl(n.get("energy-kcal_100g"))
        name = (p.get("product_name_de") or p.get("product_name") or "").strip()
        code = str(p.get("code") or "")
        if not name or kcal is None or not code.isdigit():
            continue                                    # ohne kcal oder Barcode nicht brauchbar
        marken = p.get("brands") or []
        marke = (marken[0] if isinstance(marken, list) and marken else str(marken).split(",")[0] if marken else "").strip()
        ergebnis.append(schemas.ReferenceFoodOut(
            code=code, name=name[:255], brand=marke[:255] or None,
            calories_per_100g=kcal, protein_per_100g=_zahl(n.get("proteins_100g")),
            carbs_per_100g=_zahl(n.get("carbohydrates_100g")), fat_per_100g=_zahl(n.get("fat_100g")),
            fiber_per_100g=_zahl(n.get("fiber_100g")), source="Open Food Facts",
        ))
    ergebnis = ergebnis[:15]
    _off_cache[schluessel] = (time.time(), ergebnis)
    return ergebnis

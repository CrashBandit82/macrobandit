from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, func
from typing import List, Optional
import httpx

from database import get_db
import models, schemas, auth

router = APIRouter(prefix="/api/foods", tags=["foods"])


def _get_use_count(db: Session, user_id: int, food_item_id: int) -> int:
    stat = db.query(models.UserFoodStat).filter(
        models.UserFoodStat.user_id == user_id,
        models.UserFoodStat.food_item_id == food_item_id
    ).first()
    return stat.use_count if stat else 0


def _increment_use_count(db: Session, user_id: int, food_item_id: int):
    stat = db.query(models.UserFoodStat).filter(
        models.UserFoodStat.user_id == user_id,
        models.UserFoodStat.food_item_id == food_item_id
    ).first()
    if stat:
        stat.use_count += 1
    else:
        stat = models.UserFoodStat(user_id=user_id, food_item_id=food_item_id, use_count=1)
        db.add(stat)
    db.commit()


def _family_member_ids(db: Session, exclude_id: Optional[int] = None) -> list:
    """IDs aller als Familienmitglied markierten User (DB-gestützt statt
    hartkodiert — überlebt DB-Restores mit neuen IDs)."""
    ids = [uid for (uid,) in db.query(models.User.id).filter(
        models.User.is_family_member == True
    ).all()]
    if exclude_id is not None:
        ids = [i for i in ids if i != exclude_id]
    return ids


@router.get("", response_model=List[schemas.FoodItemOut])
def list_foods(
    search: Optional[str] = None,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """
    Returns global foods + user's own foods + family shared foods.
    Sorted by: user's personal use_count DESC, then name ASC.
    """
    is_family_member = current_user.is_family_member
    family_ids = _family_member_ids(db, exclude_id=current_user.id)

    query = db.query(models.FoodItem).filter(
        or_(
            models.FoodItem.user_id == current_user.id,
            models.FoodItem.user_id == None,
            *(
                [and_(models.FoodItem.user_id.in_(family_ids), models.FoodItem.is_family == True)]
                if is_family_member else []
            )
        )
    )

    if search:
        query = query.filter(models.FoodItem.name.ilike(f"%{search}%"))

    foods = query.all()

    # Attach use counts and sort
    result = []
    for food in foods:
        food_out = schemas.FoodItemOut.from_orm(food)
        food_out.use_count = _get_use_count(db, current_user.id, food.id)
        result.append(food_out)

    result.sort(key=lambda f: (-f.use_count, f.name.lower()))
    return result


@router.post("", response_model=schemas.FoodItemOut, status_code=201)
def create_food(
    data: schemas.FoodItemCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    food = models.FoodItem(**data.dict(), user_id=current_user.id)
    db.add(food)
    db.commit()
    db.refresh(food)
    out = schemas.FoodItemOut.from_orm(food)
    out.use_count = 0
    return out


@router.get("/{food_id}", response_model=schemas.FoodItemOut)
def get_food(
    food_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    food = db.query(models.FoodItem).filter(
        models.FoodItem.id == food_id,
        or_(models.FoodItem.user_id == current_user.id, models.FoodItem.user_id == None)
    ).first()
    if not food:
        raise HTTPException(status_code=404, detail="Food item not found")
    out = schemas.FoodItemOut.from_orm(food)
    out.use_count = _get_use_count(db, current_user.id, food_id)
    return out


@router.put("/{food_id}", response_model=schemas.FoodItemOut)
def update_food(
    food_id: int,
    data: schemas.FoodItemCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    food = db.query(models.FoodItem).filter(
        models.FoodItem.id == food_id,
        models.FoodItem.user_id == current_user.id
    ).first()
    if not food:
        raise HTTPException(status_code=404, detail="Lebensmittel nicht gefunden oder nicht berechtigt")

    food.name              = data.name
    food.brand             = data.brand
    food.calories_per_100g = data.calories_per_100g
    food.protein_per_100g  = data.protein_per_100g
    food.carbs_per_100g    = data.carbs_per_100g
    food.fat_per_100g      = data.fat_per_100g
    food.fiber_per_100g    = data.fiber_per_100g
    food.portion_label     = data.portion_label
    food.portion_size_g    = data.portion_size_g
    db.commit()
    db.refresh(food)
    out = schemas.FoodItemOut.from_orm(food)
    out.use_count = _get_use_count(db, current_user.id, food.id)
    return out


@router.delete("/{food_id}", status_code=204)
def delete_food(
    food_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    food = db.query(models.FoodItem).filter(
        models.FoodItem.id == food_id,
        models.FoodItem.user_id == current_user.id   # can only delete own foods
    ).first()
    if not food:
        raise HTTPException(status_code=404, detail="Food not found or not yours to delete")
    # Stats und Logs-Referenzen vorher bereinigen
    db.query(models.UserFoodStat).filter(models.UserFoodStat.food_item_id == food_id).delete()
    db.query(models.DailyLog).filter(models.DailyLog.food_item_id == food_id).update({"food_item_id": None})
    db.delete(food)
    db.commit()


@router.post("/{food_id}/toggle-family", response_model=schemas.FoodItemOut)
def toggle_family(
    food_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    if not current_user.is_family_member:
        raise HTTPException(status_code=403, detail="Nicht berechtigt")
    food = db.query(models.FoodItem).filter(
        models.FoodItem.id == food_id,
        models.FoodItem.user_id == current_user.id
    ).first()
    if not food:
        raise HTTPException(status_code=404, detail="Lebensmittel nicht gefunden")
    food.is_family = not food.is_family
    db.commit()
    db.refresh(food)
    out = schemas.FoodItemOut.from_orm(food)
    out.use_count = _get_use_count(db, current_user.id, food.id)
    return out

# ── Barcode ───────────────────────────────────────────────────────────────────

@router.get("/barcode/{barcode}", response_model=schemas.FoodItemOut)
async def lookup_barcode(
    barcode: str,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    # Barcode muss numerisch sein (EAN/UPC 6–20 Stellen) — verhindert, dass
    # beliebige Zeichen in die ausgehende URL / DB-Suche gelangen.
    if not barcode.isdigit() or not (6 <= len(barcode) <= 20):
        raise HTTPException(status_code=400, detail="Ungültiger Barcode")

    # Check if user already has this barcode saved
    existing = db.query(models.FoodItem).filter(
        models.FoodItem.user_id == current_user.id,
        models.FoodItem.name.ilike(f"%{barcode}%")
    ).first()
    if existing:
        out = schemas.FoodItemOut.from_orm(existing)
        out.use_count = _get_use_count(db, current_user.id, existing.id)
        return out

    # Fetch from Open Food Facts
    url = f"https://world.openfoodfacts.org/api/v0/product/{barcode}.json"
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(url)

    if resp.status_code != 200:
        raise HTTPException(status_code=404, detail="Product not found")

    data = resp.json()
    if data.get("status") != 1:
        raise HTTPException(status_code=404, detail="Product not found in Open Food Facts")

    product = data["product"]
    nutriments = product.get("nutriments", {})

    name = product.get("product_name") or product.get("product_name_de") or "Unknown"
    brand = product.get("brands", "")

    food_out = schemas.FoodItemOut(
        id=0,
        user_id=None,
        name=name,
        brand=brand or None,
        calories_per_100g=nutriments.get("energy-kcal_100g"),
        protein_per_100g=nutriments.get("proteins_100g"),
        carbs_per_100g=nutriments.get("carbohydrates_100g"),
        fat_per_100g=nutriments.get("fat_100g"),
        fiber_per_100g=nutriments.get("fiber_100g"),
        use_count=0
    )
    return food_out


@router.post("/barcode/{barcode}/save", response_model=schemas.FoodItemOut, status_code=201)
async def save_barcode_food(
    barcode: str,
    data: schemas.FoodItemCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Save a barcode-scanned product to the user's personal food database."""
    food = models.FoodItem(**data.dict(), user_id=current_user.id)
    db.add(food)
    db.commit()
    db.refresh(food)
    out = schemas.FoodItemOut.from_orm(food)
    out.use_count = 0
    return out

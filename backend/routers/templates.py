from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List, Optional
from pydantic import BaseModel
from datetime import date

from database import get_db
import models, auth

router = APIRouter(prefix="/api/templates", tags=["templates"])


# ── Schemas ───────────────────────────────────────────────────────────────────

class TemplateItemIn(BaseModel):
    food_item_id: int
    amount_grams: float

class TemplateCreate(BaseModel):
    name: str
    items: List[TemplateItemIn]

class TemplateItemOut(BaseModel):
    id:           int
    food_item_id: int
    food_name:    str
    amount_grams: float
    calories:     float
    protein:      float
    carbs:        float
    fat:          float
    fiber:        float

    class Config:
        from_attributes = True

class TemplateOut(BaseModel):
    id:         int
    name:       str
    items:      List[TemplateItemOut]
    total_kcal: float

    class Config:
        from_attributes = True


def _calc(food: models.FoodItem, amount: float) -> dict:
    m = amount / 100
    return {
        "calories": round((food.calories_per_100g or 0) * m, 1),
        "protein":  round((food.protein_per_100g  or 0) * m, 1),
        "carbs":    round((food.carbs_per_100g    or 0) * m, 1),
        "fat":      round((food.fat_per_100g      or 0) * m, 1),
        "fiber":    round((food.fiber_per_100g    or 0) * m, 1),
    }


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("", response_model=List[TemplateOut])
def list_templates(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    templates = db.query(models.MealTemplate).filter(
        models.MealTemplate.user_id == current_user.id
    ).order_by(models.MealTemplate.name).all()

    result = []
    for t in templates:
        items = []
        total_kcal = 0
        for item in t.items:
            food = item.food_item
            macros = _calc(food, item.amount_grams)
            total_kcal += macros["calories"]
            items.append(TemplateItemOut(
                id=item.id,
                food_item_id=item.food_item_id,
                food_name=food.name,
                amount_grams=item.amount_grams,
                **macros
            ))
        result.append(TemplateOut(
            id=t.id, name=t.name, items=items,
            total_kcal=round(total_kcal, 1)
        ))
    return result


@router.post("", response_model=TemplateOut, status_code=201)
def create_template(
    data: TemplateCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    if not data.items:
        raise HTTPException(status_code=400, detail="Vorlage braucht mindestens ein Lebensmittel")

    template = models.MealTemplate(user_id=current_user.id, name=data.name)
    db.add(template)
    db.flush()

    items_out = []
    total_kcal = 0
    for item in data.items:
        food = db.query(models.FoodItem).filter(
            models.FoodItem.id == item.food_item_id,
            or_(models.FoodItem.user_id == current_user.id, models.FoodItem.user_id == None)
        ).first()
        if not food:
            raise HTTPException(status_code=404, detail=f"Lebensmittel {item.food_item_id} nicht gefunden")

        ti = models.MealTemplateItem(
            template_id=template.id,
            food_item_id=food.id,
            amount_grams=item.amount_grams
        )
        db.add(ti)
        macros = _calc(food, item.amount_grams)
        total_kcal += macros["calories"]
        items_out.append(TemplateItemOut(
            id=0, food_item_id=food.id, food_name=food.name,
            amount_grams=item.amount_grams, **macros
        ))

    db.commit()
    return TemplateOut(id=template.id, name=template.name, items=items_out, total_kcal=round(total_kcal, 1))


@router.put("/{template_id}", response_model=TemplateOut)
def update_template(
    template_id: int,
    data: TemplateCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Name und Lebensmittel einer eigenen Vorlage ersetzen."""
    template = db.query(models.MealTemplate).filter(
        models.MealTemplate.id == template_id,
        models.MealTemplate.user_id == current_user.id
    ).first()
    if not template:
        raise HTTPException(status_code=404, detail="Vorlage nicht gefunden")
    if not data.name.strip():
        raise HTTPException(status_code=400, detail="Vorlage braucht einen Namen")
    if not data.items:
        raise HTTPException(status_code=400, detail="Vorlage braucht mindestens ein Lebensmittel")

    # Erst alle Lebensmittel prüfen, dann ändern
    foods = []
    for item in data.items:
        food = db.query(models.FoodItem).filter(
            models.FoodItem.id == item.food_item_id,
            or_(models.FoodItem.user_id == current_user.id, models.FoodItem.user_id == None)
        ).first()
        if not food:
            raise HTTPException(status_code=404, detail=f"Lebensmittel {item.food_item_id} nicht gefunden")
        if item.amount_grams <= 0:
            raise HTTPException(status_code=400, detail="Menge muss größer als 0 sein")
        foods.append((food, item.amount_grams))

    template.name = data.name.strip()
    template.items.clear()
    db.flush()

    items_out = []
    total_kcal = 0
    for food, amount in foods:
        template.items.append(models.MealTemplateItem(food_item_id=food.id, amount_grams=amount))
        macros = _calc(food, amount)
        total_kcal += macros["calories"]
        items_out.append(TemplateItemOut(
            id=0, food_item_id=food.id, food_name=food.name,
            amount_grams=amount, **macros
        ))

    db.commit()
    return TemplateOut(id=template.id, name=template.name, items=items_out, total_kcal=round(total_kcal, 1))


@router.post("/{template_id}/apply")
def apply_template(
    template_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Vorlage als einen aggregierten Log-Eintrag eintragen."""
    template = db.query(models.MealTemplate).filter(
        models.MealTemplate.id == template_id,
        models.MealTemplate.user_id == current_user.id
    ).first()
    if not template:
        raise HTTPException(status_code=404, detail="Vorlage nicht gefunden")

    # Alle Makros summieren
    total = {"calories": 0.0, "protein": 0.0, "carbs": 0.0, "fat": 0.0, "fiber": 0.0}
    total_grams = 0.0

    for item in template.items:
        food = item.food_item
        macros = _calc(food, item.amount_grams)
        for k in total:
            total[k] += macros[k]
        total_grams += item.amount_grams

        # Use count erhöhen
        stat = db.query(models.UserFoodStat).filter(
            models.UserFoodStat.user_id == current_user.id,
            models.UserFoodStat.food_item_id == food.id
        ).first()
        if stat:
            stat.use_count += 1
        else:
            db.add(models.UserFoodStat(user_id=current_user.id, food_item_id=food.id, use_count=1))

    # Runden
    for k in total:
        total[k] = round(total[k], 1)

    # Einen einzigen Log-Eintrag mit Vorlagenname
    log = models.DailyLog(
        user_id=current_user.id,
        food_item_id=None,
        food_name=f"📋 {template.name}",
        amount_grams=round(total_grams, 1),
        date=date.today(),
        **total
    )
    db.add(log)
    db.commit()
    return {"message": f"Vorlage '{template.name}' eingetragen", "count": 1}


@router.delete("/{template_id}", status_code=204)
def delete_template(
    template_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    template = db.query(models.MealTemplate).filter(
        models.MealTemplate.id == template_id,
        models.MealTemplate.user_id == current_user.id
    ).first()
    if not template:
        raise HTTPException(status_code=404, detail="Vorlage nicht gefunden")
    db.delete(template)
    db.commit()

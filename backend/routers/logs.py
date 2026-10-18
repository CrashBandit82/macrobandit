from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from typing import List
from datetime import date

from database import get_db
import models, schemas, auth
from routers.foods import _increment_use_count, _family_member_ids

router = APIRouter(prefix="/api/logs", tags=["logs"])


def _calc_macros(food: models.FoodItem, amount_grams: float) -> dict:
    m = amount_grams / 100
    return {
        "calories": round((food.calories_per_100g or 0) * m, 1),
        "protein":  round((food.protein_per_100g  or 0) * m, 1),
        "carbs":    round((food.carbs_per_100g    or 0) * m, 1),
        "fat":      round((food.fat_per_100g      or 0) * m, 1),
        "fiber":    round((food.fiber_per_100g    or 0) * m, 1),
    }


@router.post("", response_model=schemas.LogOut, status_code=201)
def add_log(
    data: schemas.LogCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    family_ids = _family_member_ids(db, exclude_id=current_user.id)
    food = db.query(models.FoodItem).filter(
        models.FoodItem.id == data.food_item_id,
        or_(
            models.FoodItem.user_id == current_user.id,
            models.FoodItem.user_id == None,
            *(
                [and_(models.FoodItem.user_id.in_(family_ids), models.FoodItem.is_family == True)]
                if current_user.is_family_member else []
            )
        )
    ).first()
    if not food:
        raise HTTPException(status_code=404, detail="Lebensmittel nicht gefunden")

    macros = _calc_macros(food, data.amount_grams)
    log = models.DailyLog(
        user_id=current_user.id,
        food_item_id=food.id,
        food_name=food.name,
        amount_grams=data.amount_grams,
        date=date.today(),
        **macros
    )
    db.add(log)
    _increment_use_count(db, current_user.id, food.id)
    db.commit()
    db.refresh(log)
    return log


@router.get("/today", response_model=List[schemas.LogOut])
def get_today(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(models.DailyLog).filter(
        models.DailyLog.user_id == current_user.id,
        models.DailyLog.date == date.today()
    ).order_by(models.DailyLog.created_at).all()


@router.get("/date/{log_date}", response_model=List[schemas.LogOut])
def get_by_date(
    log_date: date,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(models.DailyLog).filter(
        models.DailyLog.user_id == current_user.id,
        models.DailyLog.date == log_date
    ).order_by(models.DailyLog.created_at).all()


@router.delete("/{log_id}", status_code=204)
def delete_log(
    log_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    log = db.query(models.DailyLog).filter(
        models.DailyLog.id == log_id,
        models.DailyLog.user_id == current_user.id
    ).first()
    if not log:
        raise HTTPException(status_code=404, detail="Eintrag nicht gefunden")
    db.delete(log)
    db.commit()

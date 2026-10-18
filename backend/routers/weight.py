from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import date, timedelta
from pydantic import BaseModel

from database import get_db
import models, auth

router = APIRouter(prefix="/api/weight", tags=["weight"])


class WeightCreate(BaseModel):
    weight_kg: float
    date: Optional[date] = None


class WeightOut(BaseModel):
    id: int
    weight_kg: float
    date: date

    class Config:
        from_attributes = True


class WeightHistory(BaseModel):
    entries: List[WeightOut]
    latest: Optional[float] = None
    start_weight: Optional[float] = None
    trend: Optional[float] = None   # Differenz letzte 7 Tage


class ProfileUpdate(BaseModel):
    gender:    Optional[str] = None
    age:       Optional[int] = None
    height_cm: Optional[int] = None


@router.post("", response_model=WeightOut, status_code=201)
def log_weight(
    data: WeightCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    if data.weight_kg <= 0 or data.weight_kg > 500:
        raise HTTPException(status_code=400, detail="Ungültiges Gewicht")

    target_date = data.date or date.today()

    # Bereits ein Eintrag für diesen Tag? → aktualisieren
    existing = db.query(models.WeightLog).filter(
        models.WeightLog.user_id == current_user.id,
        models.WeightLog.date == target_date
    ).first()

    if existing:
        existing.weight_kg = data.weight_kg
        db.commit()
        db.refresh(existing)
        return existing

    entry = models.WeightLog(
        user_id=current_user.id,
        weight_kg=data.weight_kg,
        date=target_date
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.get("/history", response_model=WeightHistory)
def get_history(
    days: int = 30,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    since = date.today() - timedelta(days=days)
    entries = db.query(models.WeightLog).filter(
        models.WeightLog.user_id == current_user.id,
        models.WeightLog.date >= since
    ).order_by(models.WeightLog.date).all()

    latest      = entries[-1].weight_kg if entries else None
    start       = entries[0].weight_kg  if entries else None
    trend       = None

    if len(entries) >= 2:
        recent = [e for e in entries if e.date >= date.today() - timedelta(days=7)]
        older  = [e for e in entries if e.date <  date.today() - timedelta(days=7)]
        if recent and older:
            trend = round(recent[-1].weight_kg - older[-1].weight_kg, 1)

    return WeightHistory(
        entries=[WeightOut.from_orm(e) for e in entries],
        latest=latest,
        start_weight=start,
        trend=trend
    )


@router.delete("/{entry_id}", status_code=204)
def delete_entry(
    entry_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    entry = db.query(models.WeightLog).filter(
        models.WeightLog.id == entry_id,
        models.WeightLog.user_id == current_user.id
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Eintrag nicht gefunden")
    db.delete(entry)
    db.commit()


@router.put("/profile")
def update_profile(
    data: ProfileUpdate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    if data.gender is not None:    current_user.gender    = data.gender
    if data.age is not None:       current_user.age       = data.age
    if data.height_cm is not None: current_user.height_cm = data.height_cm
    db.commit()
    db.refresh(current_user)
    return {"gender": current_user.gender, "age": current_user.age, "height_cm": current_user.height_cm}

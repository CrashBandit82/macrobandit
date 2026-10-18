from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date, timedelta

from database import get_db
import models, schemas, auth

router = APIRouter(prefix="/api", tags=["stats"])

GERMAN_DAYS = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]


def _totals_for_date(db: Session, user_id: int, target_date: date) -> schemas.DailyTotals:
    result = db.query(
        func.coalesce(func.sum(models.DailyLog.calories), 0),
        func.coalesce(func.sum(models.DailyLog.protein),  0),
        func.coalesce(func.sum(models.DailyLog.carbs),    0),
        func.coalesce(func.sum(models.DailyLog.fat),      0),
        func.coalesce(func.sum(models.DailyLog.fiber),    0),
        func.count(models.DailyLog.id)
    ).filter(
        models.DailyLog.user_id == user_id,
        models.DailyLog.date == target_date
    ).first()

    return schemas.DailyTotals(
        calories=round(result[0], 1),
        protein= round(result[1], 1),
        carbs=   round(result[2], 1),
        fat=     round(result[3], 1),
        fiber=   round(result[4], 1),
        entries= result[5]
    )


@router.get("/totals/today", response_model=schemas.DailyTotals)
def totals_today(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    return _totals_for_date(db, current_user.id, date.today())


@router.get("/totals/date/{target_date}", response_model=schemas.DailyTotals)
def totals_by_date(
    target_date: date,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    return _totals_for_date(db, current_user.id, target_date)


@router.get("/weekly", response_model=schemas.WeeklyStats)
def weekly_stats(
    calorie_goal: int = 2000,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    today = date.today()
    week_start = today - timedelta(days=today.weekday())  # Montag
    week_end   = week_start + timedelta(days=6)

    days = []
    weekly_total = 0.0

    for i in range(7):
        day = week_start + timedelta(days=i)
        totals = _totals_for_date(db, current_user.id, day)
        weekly_total += totals.calories
        days.append(schemas.DayCalories(
            date=day,
            day_name=GERMAN_DAYS[i],
            calories=totals.calories,
            goal_reached=totals.calories >= calorie_goal
        ))

    days_with_data = [d for d in days if d.calories > 0]
    avg = weekly_total / len(days_with_data) if days_with_data else 0

    return schemas.WeeklyStats(
        week_start=week_start,
        week_end=week_end,
        days=days,
        weekly_total=round(weekly_total, 1),
        weekly_goal=calorie_goal * 7,
        avg_daily=round(avg, 1)
    )


@router.get("/monthly")
def monthly_stats(
    year:  int = None,
    month: int = None,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    from calendar import monthrange
    from datetime import datetime

    today = date.today()
    if not year:  year  = today.year
    if not month: month = today.month

    _, days_in_month = monthrange(year, month)
    month_start = date(year, month, 1)
    month_end   = date(year, month, days_in_month)

    # Alle Logs des Monats
    logs = db.query(
        models.DailyLog.date,
        func.coalesce(func.sum(models.DailyLog.calories), 0).label("calories"),
        func.coalesce(func.sum(models.DailyLog.protein),  0).label("protein"),
        func.coalesce(func.sum(models.DailyLog.carbs),    0).label("carbs"),
        func.coalesce(func.sum(models.DailyLog.fat),      0).label("fat"),
        func.coalesce(func.sum(models.DailyLog.fiber),    0).label("fiber"),
    ).filter(
        models.DailyLog.user_id == current_user.id,
        models.DailyLog.date >= month_start,
        models.DailyLog.date <= month_end
    ).group_by(models.DailyLog.date).all()

    if not logs:
        return {
            "year": year, "month": month,
            "days_tracked": 0, "days_in_month": days_in_month,
            "avg_calories": 0, "avg_protein": 0, "avg_carbs": 0, "avg_fat": 0, "avg_fiber": 0,
            "total_calories": 0, "best_day": None, "worst_day": None,
            "goal_reached_days": 0, "daily": []
        }

    goal_kcal = current_user.goal_kcal or 2000
    total_cal = sum(r.calories for r in logs)
    n = len(logs)

    best  = max(logs, key=lambda r: r.calories)
    worst = min(logs, key=lambda r: r.calories)

    goal_days = sum(1 for r in logs if r.calories >= goal_kcal)

    daily = [
        {
            "date": r.date.strftime("%d.%m."),
            "calories": round(r.calories, 0),
            "protein":  round(r.protein, 1),
            "goal_reached": r.calories >= goal_kcal
        }
        for r in sorted(logs, key=lambda r: r.date)
    ]

    return {
        "year": year, "month": month,
        "days_tracked": n,
        "days_in_month": days_in_month,
        "avg_calories": round(total_cal / n, 0),
        "avg_protein":  round(sum(r.protein for r in logs) / n, 1),
        "avg_carbs":    round(sum(r.carbs   for r in logs) / n, 1),
        "avg_fat":      round(sum(r.fat     for r in logs) / n, 1),
        "avg_fiber":    round(sum(r.fiber   for r in logs) / n, 1),
        "total_calories": round(total_cal, 0),
        "goal_reached_days": goal_days,
        "best_day":  {"date": best.date.strftime("%d.%m."),  "calories": round(best.calories, 0)},
        "worst_day": {"date": worst.date.strftime("%d.%m."), "calories": round(worst.calories, 0)},
        "daily": daily
    }

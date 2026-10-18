from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
import os, json

from database import get_db
import models, auth

router = APIRouter(prefix="/api/push", tags=["push"])


class PushSubscription(BaseModel):
    endpoint: str
    p256dh:   str
    auth:     str


class PushNotification(BaseModel):
    title:   str
    body:    str
    user_id: Optional[int] = None  # None = alle User


@router.get("/vapid-public-key")
def get_vapid_key():
    return {"public_key": os.getenv("VAPID_PUBLIC_KEY")}


@router.post("/subscribe")
def subscribe(
    data: PushSubscription,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    existing = db.query(models.PushSubscription).filter(
        models.PushSubscription.endpoint == data.endpoint
    ).first()
    if existing and existing.user_id != current_user.id:
        # Endpoint gehört einem anderen User (z.B. weitergegebenes Gerät):
        # alten Datensatz entfernen und für den aktuellen User neu anlegen,
        # damit niemand fremde Push-Zustellung kapern/überschreiben kann.
        db.delete(existing)
        db.flush()
        existing = None
    if existing:
        existing.p256dh = data.p256dh
        existing.auth   = data.auth
    else:
        sub = models.PushSubscription(
            user_id=current_user.id,
            endpoint=data.endpoint,
            p256dh=data.p256dh,
            auth=data.auth
        )
        db.add(sub)
    db.commit()
    return {"message": "Abonniert"}


@router.delete("/unsubscribe")
def unsubscribe(
    data: PushSubscription,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    db.query(models.PushSubscription).filter(
        models.PushSubscription.endpoint == data.endpoint,
        models.PushSubscription.user_id == current_user.id
    ).delete()
    db.commit()
    return {"message": "Abgemeldet"}


@router.post("/send")
def send_notification(
    data: PushNotification,
    admin: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    if not admin.is_admin:
        from fastapi import HTTPException
        raise HTTPException(status_code=403, detail="Kein Admin-Zugriff")
    from pywebpush import webpush, WebPushException

    vapid_private = os.getenv("VAPID_PRIVATE_KEY", "").replace("\\n", "\n")
    vapid_claims  = {"sub": os.getenv("VAPID_CLAIMS", "mailto:trainer@macrobandit.at")}

    query = db.query(models.PushSubscription)
    if data.user_id:
        query = query.filter(models.PushSubscription.user_id == data.user_id)
    subs = query.all()

    sent = 0
    failed = []
    for sub in subs:
        try:
            webpush(
                subscription_info={
                    "endpoint": sub.endpoint,
                    "keys": {"p256dh": sub.p256dh, "auth": sub.auth}
                },
                data=json.dumps({"title": data.title, "body": data.body}),
                vapid_private_key=vapid_private,
                vapid_claims=vapid_claims
            )
            sent += 1
        except WebPushException as e:
            if "410" in str(e) or "404" in str(e):
                db.delete(sub)
            failed.append(str(e))

    db.commit()
    return {"sent": sent, "failed": len(failed)}

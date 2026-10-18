#!/usr/bin/env python3
"""
Täglich per Cronjob aufrufen — sendet Push-Erinnerungen zur eingestellten Uhrzeit.
Cronjob: * * * * * cd /opt/macrobandit/backend && source venv/bin/activate && python3 send_reminders.py
"""
import os, sys, json
from datetime import datetime, date, timezone
sys.path.insert(0, '/opt/macrobandit/backend')
from dotenv import load_dotenv
load_dotenv('/opt/macrobandit/backend/.env')

from database import SessionLocal
import models
from pywebpush import webpush, WebPushException

db = SessionLocal()

now_time = datetime.now().strftime("%H:%M")

# User mit passender Reminder-Zeit die heute noch keine Logs haben
users = db.query(models.User).filter(
    models.User.reminder_time == now_time,
    models.User.is_active == True,
    models.User.is_verified == True
).all()

vapid_private = os.getenv("VAPID_PRIVATE_KEY", "").replace("\\n", "\n")
vapid_claims  = {"sub": os.getenv("VAPID_CLAIMS", "mailto:trainer@macrobandit.at")}

sent = 0
for user in users:
    # Prüfen ob heute schon Logs vorhanden
    has_logs = db.query(models.DailyLog).filter(
        models.DailyLog.user_id == user.id,
        models.DailyLog.date == date.today()
    ).first()

    if has_logs:
        continue  # Heute schon eingetragen — keine Erinnerung

    # Push senden
    subs = db.query(models.PushSubscription).filter(
        models.PushSubscription.user_id == user.id
    ).all()

    for sub in subs:
        try:
            webpush(
                subscription_info={
                    "endpoint": sub.endpoint,
                    "keys": {"p256dh": sub.p256dh, "auth": sub.auth}
                },
                data=json.dumps({
                    "title": "MacroBandit 🥗",
                    "body": f"Hey {user.username}! Vergiss nicht deine heutigen Mahlzeiten einzutragen."
                }),
                vapid_private_key=vapid_private,
                vapid_claims=vapid_claims
            )
            sent += 1
        except WebPushException as e:
            if "410" in str(e) or "404" in str(e):
                db.delete(sub)

db.commit()
db.close()
print(f"Erinnerungen gesendet: {sent}")

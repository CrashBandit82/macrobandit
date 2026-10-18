from fastapi import APIRouter, Depends, HTTPException
import os, smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from concurrent.futures import ThreadPoolExecutor
_executor = ThreadPoolExecutor(max_workers=2)
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from datetime import date
from pydantic import BaseModel
from typing import Optional

from database import get_db
import models, auth

router = APIRouter(prefix="/api/admin", tags=["admin"])


# ── Admin Dependency ──────────────────────────────────────────────────────────

def get_admin_user(current_user: models.User = Depends(auth.get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Kein Admin-Zugriff")
    return current_user


# ── Schemas ───────────────────────────────────────────────────────────────────

class AdminUserOut(BaseModel):
    id:          int
    username:    str
    email:       str
    is_active:   bool
    is_verified: bool
    is_admin:    bool
    created_at:  str
    log_count:   int
    last_active: Optional[str] = None

    class Config:
        from_attributes = True


class BroadcastMessage(BaseModel):
    subject: str
    message: str

class InactivityNotice(BaseModel):
    days_inactive: int = 30
    warning_days:  int = 7  # "wird in X Tagen gelöscht"


# ── Email Helper ──────────────────────────────────────────────────────────────

def _send_email(to: str, subject: str, html: str, text: str):
    try:
        smtp_host     = os.getenv("SMTP_HOST")
        smtp_port     = int(os.getenv("SMTP_PORT", 587))
        smtp_user     = os.getenv("SMTP_USER")
        smtp_password = os.getenv("SMTP_PASSWORD")
        if not all([smtp_host, smtp_user, smtp_password]):
            return False
        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"]    = smtp_user
        msg["To"]      = to
        msg.attach(MIMEText(text, "plain"))
        msg.attach(MIMEText(html, "html"))
        with smtplib.SMTP(smtp_host, smtp_port, timeout=10) as server:
            server.ehlo(); server.starttls()
            server.login(smtp_user, smtp_password)
            server.sendmail(smtp_user, to, msg.as_string())
        return True
    except Exception as e:
        import logging
        logging.getLogger("macrobandit").warning(f"Admin E-Mail fehlgeschlagen an {to}: {e}")
        return False


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/users", response_model=List[AdminUserOut])
def list_users(
    admin: models.User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    users = db.query(models.User).order_by(models.User.created_at.desc()).all()
    result = []
    for u in users:
        log_count = db.query(func.count(models.DailyLog.id)).filter(
            models.DailyLog.user_id == u.id
        ).scalar() or 0

        last_log = db.query(func.max(models.DailyLog.date)).filter(
            models.DailyLog.user_id == u.id
        ).scalar()

        result.append(AdminUserOut(
            id=u.id,
            username=u.username,
            email=u.email,
            is_active=u.is_active,
            is_verified=u.is_verified,
            is_admin=u.is_admin,
            created_at=u.created_at.astimezone().strftime("%d.%m.%Y %H:%M") if u.created_at else "—",
            log_count=log_count,
            last_active=last_log.strftime("%d.%m.%Y") if last_log else None
        ))
    return result


@router.delete("/users/{user_id}")
def delete_user(
    user_id: int,
    admin: models.User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    if user_id == admin.id:
        raise HTTPException(status_code=400, detail="Du kannst deinen eigenen Account nicht löschen")

    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User nicht gefunden")

    # Avatar löschen
    if user.avatar_path:
        from pathlib import Path
        try:
            p = Path("/opt/macrobandit/uploads") / user.avatar_path.lstrip("/")
            if p.exists(): p.unlink()
        except Exception:
            pass

    # Alle Daten löschen
    db.query(models.EmailVerificationToken).filter(models.EmailVerificationToken.user_id == user_id).delete()
    db.query(models.PasswordResetToken).filter(models.PasswordResetToken.user_id == user_id).delete()
    db.query(models.UserFoodStat).filter(models.UserFoodStat.user_id == user_id).delete()
    db.query(models.DailyLog).filter(models.DailyLog.user_id == user_id).delete()
    db.query(models.WeightLog).filter(models.WeightLog.user_id == user_id).delete()
    db.query(models.FoodItem).filter(models.FoodItem.user_id == user_id).delete()
    db.delete(user)
    db.commit()
    return {"message": f"User {user.username} gelöscht"}


@router.put("/users/{user_id}/toggle-active")
def toggle_active(
    user_id: int,
    admin: models.User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    if user_id == admin.id:
        raise HTTPException(status_code=400, detail="Eigenen Account nicht deaktivierbar")
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User nicht gefunden")
    user.is_active = not user.is_active
    db.commit()
    return {"message": f"User {'aktiviert' if user.is_active else 'deaktiviert'}", "is_active": user.is_active}


@router.put("/users/{user_id}/toggle-verified")
def toggle_verified(
    user_id: int,
    admin: models.User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User nicht gefunden")
    user.is_verified = not user.is_verified
    db.commit()
    return {"message": f"Verifizierung {'aktiviert' if user.is_verified else 'deaktiviert'}", "is_verified": user.is_verified}


@router.post("/users/{user_id}/resend-verification")
def admin_resend_verification(
    user_id: int,
    admin: models.User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User nicht gefunden")
    if user.is_verified:
        raise HTTPException(status_code=400, detail="User ist bereits verifiziert")

    import secrets
    from datetime import datetime, timedelta, timezone
    from routers.auth import send_verification_email

    # Alte Tokens ungültig machen
    db.query(models.EmailVerificationToken).filter(
        models.EmailVerificationToken.user_id == user.id,
        models.EmailVerificationToken.used == False
    ).update({"used": True})

    token = secrets.token_urlsafe(32)
    expires = datetime.now(timezone.utc) + timedelta(hours=24)
    verify = models.EmailVerificationToken(user_id=user.id, token=token, expires_at=expires)
    db.add(verify)
    db.commit()

    _executor.submit(send_verification_email, user.username, user.email, token)
    return {"message": f"Verifikations-E-Mail gesendet an {user.email}"}


@router.post("/broadcast")
def broadcast_message(
    data: BroadcastMessage,
    admin: models.User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Sendet E-Mail an alle verifizierten und aktiven User."""
    users = db.query(models.User).filter(
        models.User.is_verified == True,
        models.User.is_active == True
    ).all()

    if not users:
        raise HTTPException(status_code=400, detail="Keine User gefunden")

    html_template = f"""
<html><body style="font-family:sans-serif;background:#0f172a;color:#e2e8f0;padding:32px;">
  <div style="max-width:480px;margin:0 auto;background:#1e293b;border-radius:16px;padding:32px;border:1px solid #334155;">
    <h2 style="color:#34d399;margin-top:0;">📢 MacroBandit</h2>
    <div style="color:#e2e8f0;line-height:1.8;white-space:pre-wrap;">{data.message}</div>
    <hr style="border-color:#334155;margin:24px 0;">
    <p style="color:#475569;font-size:12px;margin:0;">macrobandit.at · trainer@macrobandit.at</p>
  </div>
</body></html>"""

    def _send_all():
        sent = 0
        for user in users:
            personalized = html_template.replace("{username}", user.username)
            if _send_email(user.email, data.subject, personalized, data.message):
                sent += 1
        import logging
        logging.getLogger("macrobandit").info(f"Broadcast gesendet: {sent}/{len(users)} User")

    _executor.submit(_send_all)
    return {"message": f"Wird gesendet an {len(users)} User", "count": len(users)}


@router.post("/notify-inactive")
def notify_inactive(
    data: InactivityNotice,
    admin: models.User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Sendet Inaktivitäts-Warnung an User ohne Logs seit X Tagen."""
    from datetime import datetime, timedelta
    cutoff = date.today() - timedelta(days=data.days_inactive)

    # User die seit X Tagen keinen Log haben
    inactive_users = []
    users = db.query(models.User).filter(
        models.User.is_verified == True,
        models.User.is_active == True,
        models.User.is_admin == False
    ).all()

    for user in users:
        last_log = db.query(func.max(models.DailyLog.date)).filter(
            models.DailyLog.user_id == user.id
        ).scalar()
        # Kein Log je oder letzter Log älter als cutoff
        if last_log is None or last_log < cutoff:
            inactive_users.append(user)

    if not inactive_users:
        return {"message": "Keine inaktiven User gefunden", "count": 0}

    def _send_warnings():
        sent = 0
        for user in inactive_users:
            html = f"""
<html><body style="font-family:sans-serif;background:#0f172a;color:#e2e8f0;padding:32px;">
  <div style="max-width:480px;margin:0 auto;background:#1e293b;border-radius:16px;padding:32px;border:1px solid #334155;">
    <h2 style="color:#f59e0b;margin-top:0;">⚠️ Inaktivitäts-Hinweis</h2>
    <p style="color:#94a3b8;">Hallo <strong style="color:#f1f5f9;">{user.username}</strong>,</p>
    <p style="color:#94a3b8;">dein MacroBandit Konto war seit über <strong style="color:#f1f5f9;">{data.days_inactive} Tagen</strong> inaktiv.</p>
    <p style="color:#94a3b8;">Falls du das Konto nicht mehr benötigst, wird es in <strong style="color:#f59e0b;">{data.warning_days} Tagen</strong> gelöscht.</p>
    <div style="text-align:center;margin:28px 0;">
      <a href="https://macrobandit.at" style="background:linear-gradient(to right,#34d399,#22d3ee);color:#0f172a;font-weight:900;padding:14px 32px;border-radius:12px;text-decoration:none;font-size:15px;">
        Jetzt wieder einloggen
      </a>
    </div>
    <p style="color:#475569;font-size:12px;">Falls du dein Konto behalten möchtest, melde dich einfach an. Die Löschung erfolgt nur wenn du inaktiv bleibst.</p>
    <hr style="border-color:#334155;margin:24px 0;">
    <p style="color:#475569;font-size:12px;margin:0;">macrobandit.at · trainer@macrobandit.at</p>
  </div>
</body></html>"""
            text = (f"Hallo {user.username},\n\ndein Konto war seit {data.days_inactive} Tagen inaktiv "
                   f"und wird in {data.warning_days} Tagen gelöscht.\n\nMelde dich an um es zu behalten:\nhttps://macrobandit.at")
            if _send_email(user.email, "⚠️ MacroBandit — Inaktivitäts-Hinweis", html, text):
                sent += 1
        import logging
        logging.getLogger("macrobandit").info(f"Inaktivitäts-Warnungen: {sent}/{len(inactive_users)} gesendet")

    _executor.submit(_send_warnings)
    return {"message": f"Wird gesendet an {len(inactive_users)} inaktive User", "count": len(inactive_users)}


@router.get("/stats")
def admin_stats(
    admin: models.User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    total_users    = db.query(func.count(models.User.id)).scalar()
    verified_users = db.query(func.count(models.User.id)).filter(models.User.is_verified == True).scalar()
    total_logs     = db.query(func.count(models.DailyLog.id)).scalar()
    today_logs     = db.query(func.count(models.DailyLog.id)).filter(
        models.DailyLog.date == date.today()
    ).scalar()

    return {
        "total_users":    total_users,
        "verified_users": verified_users,
        "total_logs":     total_logs,
        "today_logs":     today_logs,
    }

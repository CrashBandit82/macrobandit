from fastapi import APIRouter, Depends, HTTPException, status, Request, UploadFile, File
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from slowapi import Limiter
from slowapi.util import get_remote_address
import smtplib
import os
import uuid
import secrets
from html import escape as html_escape
from pathlib import Path
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta, timezone
from concurrent.futures import ThreadPoolExecutor

_executor = ThreadPoolExecutor(max_workers=2)

from database import get_db
import models, schemas, auth

router = APIRouter(prefix="/api/auth", tags=["auth"])
limiter = Limiter(key_func=get_remote_address)

AVATAR_DIR = Path("/opt/macrobandit/uploads/avatars")
AVATAR_DIR.mkdir(parents=True, exist_ok=True)
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_SIZE_BYTES = 5 * 1024 * 1024  # 5MB


def _is_expired(expires_at) -> bool:
    """Vergleicht Ablaufdatum robust gegen jetzt — auch wenn die Spalte
    (nach DB-Wechsel) timezone-naiv geliefert wird."""
    if expires_at is None:
        return True
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    return expires_at < datetime.now(timezone.utc)


def _csv_safe(value):
    """Verhindert CSV-/Formel-Injection: Zellen, die mit = + - @ beginnen,
    werden mit führendem Apostroph neutralisiert."""
    if isinstance(value, str) and value and value[0] in ("=", "+", "-", "@"):
        return "'" + value
    return value


def send_welcome_email(username: str, email: str):
    """Sendet Willkommens-E-Mail mit Schnellstart-Anleitung nach erfolgreicher Verifikation."""
    try:
        smtp_host     = os.getenv("SMTP_HOST")
        smtp_port     = int(os.getenv("SMTP_PORT", 587))
        smtp_user     = os.getenv("SMTP_USER")
        smtp_password = os.getenv("SMTP_PASSWORD")
        if not all([smtp_host, smtp_user, smtp_password]):
            return

        import pathlib
        template_path = pathlib.Path("/opt/macrobandit/backend/templates/welcome.html")
        if not template_path.exists():
            return
        html = template_path.read_text(encoding="utf-8").replace("{username}", username)

        msg = MIMEMultipart("alternative")
        msg["Subject"] = f"🥗 Willkommen bei MacroBandit, {username}!"
        msg["From"]    = smtp_user
        msg["To"]      = email

        text = (f"Hallo {username}!\n\n"
                f"Deine E-Mail wurde bestätigt. Du kannst dich jetzt anmelden.\n\n"
                f"Schnellstart:\n"
                f"1. Makro-Ziele setzen (Makro-Ziele anpassen Button)\n"
                f"2. Erste Mahlzeit eintragen (+ Button)\n"
                f"3. Barcode scannen für schnelles Eintragen\n\n"
                f"App installieren: macrobandit.at im Browser öffnen\n"
                f"iOS: Teilen → Zum Home-Bildschirm\n"
                f"Android: Menü → App installieren\n\n"
                f"Viel Erfolg!\nmacrobandit.at")

        msg.attach(MIMEText(text, "plain"))
        msg.attach(MIMEText(html, "html"))

        with smtplib.SMTP(smtp_host, smtp_port, timeout=10) as server:
            server.ehlo(); server.starttls()
            server.login(smtp_user, smtp_password)
            server.sendmail(smtp_user, email, msg.as_string())
    except Exception as e:
        import logging
        logging.getLogger("macrobandit").warning(f"Welcome-E-Mail fehlgeschlagen: {e}")


def send_verification_email(username: str, email: str, token: str):
    """Sendet E-Mail Verifikationslink an neuen User."""
    try:
        smtp_host     = os.getenv("SMTP_HOST")
        smtp_port     = int(os.getenv("SMTP_PORT", 587))
        smtp_user     = os.getenv("SMTP_USER")
        smtp_password = os.getenv("SMTP_PASSWORD")
        if not all([smtp_host, smtp_user, smtp_password]):
            return
        verify_url = f"https://macrobandit.at/verify-email?token={token}"
        msg = MIMEMultipart("alternative")
        msg["Subject"] = "✅ MacroBandit — E-Mail bestätigen"
        msg["From"]    = smtp_user
        msg["To"]      = email
        text = f"Hallo {username},\n\nBitte bestätige deine E-Mail:\n{verify_url}\n\nDer Link ist 24 Stunden gültig."
        html = f"""
<html><body style="font-family:sans-serif;background:#0f172a;color:#e2e8f0;padding:32px;">
  <div style="max-width:480px;margin:0 auto;background:#1e293b;border-radius:16px;padding:32px;border:1px solid #334155;">
    <h2 style="color:#34d399;margin-top:0;">✅ E-Mail bestätigen</h2>
    <p style="color:#94a3b8;">Hallo <strong style="color:#f1f5f9;">{username}</strong>,</p>
    <p style="color:#94a3b8;">Willkommen bei MacroBandit! Bitte bestätige deine E-Mail-Adresse.</p>
    <div style="text-align:center;margin:32px 0;">
      <a href="{verify_url}" style="background:linear-gradient(to right,#34d399,#22d3ee);color:#0f172a;font-weight:900;padding:14px 32px;border-radius:12px;text-decoration:none;font-size:16px;">
        E-Mail bestätigen
      </a>
    </div>
    <p style="color:#475569;font-size:12px;">Der Link ist <strong>24 Stunden</strong> gültig.</p>
    <hr style="border-color:#334155;margin:24px 0;">
    <p style="color:#475569;font-size:11px;word-break:break-all;">{verify_url}</p>
  </div>
</body></html>"""
        msg.attach(MIMEText(text, "plain"))
        msg.attach(MIMEText(html, "html"))
        with smtplib.SMTP(smtp_host, smtp_port, timeout=10) as server:
            server.ehlo(); server.starttls()
            server.login(smtp_user, smtp_password)
            server.sendmail(smtp_user, email, msg.as_string())
    except Exception as e:
        import logging
        logging.getLogger("macrobandit").warning(f"Verifikations-E-Mail fehlgeschlagen: {e}")


def send_registration_email(username: str, email: str):
    try:
        smtp_host     = os.getenv("SMTP_HOST")
        smtp_port     = int(os.getenv("SMTP_PORT", 587))
        smtp_user     = os.getenv("SMTP_USER")
        smtp_password = os.getenv("SMTP_PASSWORD")
        notify_email  = os.getenv("NOTIFY_EMAIL")

        if not all([smtp_host, smtp_user, smtp_password, notify_email]):
            return

        msg = MIMEMultipart("alternative")
        msg["Subject"] = f"🥗 MacroBandit — Neuer User: {username}"
        msg["From"]    = smtp_user
        msg["To"]      = notify_email

        now = datetime.now().strftime("%d.%m.%Y um %H:%M Uhr")

        text = f"Neuer User registriert!\n\nBenutzername: {username}\nRegistriert: {now}\n\nmacrobandit.at"
        html = f"""
<html><body style="font-family:sans-serif;background:#0f172a;color:#e2e8f0;padding:32px;">
  <div style="max-width:480px;margin:0 auto;background:#1e293b;border-radius:16px;padding:32px;border:1px solid #334155;">
    <h2 style="color:#34d399;margin-top:0;">🥗 Neuer User auf MacroBandit!</h2>
    <table style="width:100%;border-collapse:collapse;">
      <tr>
        <td style="color:#94a3b8;padding:8px 0;width:140px;">Benutzername</td>
        <td style="color:#f1f5f9;font-weight:bold;">{username}</td>
      </tr>
      <tr>
        <td style="color:#94a3b8;padding:8px 0;">Registriert am</td>
        <td style="color:#f1f5f9;">{now}</td>
      </tr>
    </table>
    <hr style="border-color:#334155;margin:24px 0;">
    <p style="color:#475569;font-size:12px;margin:0;">macrobandit.at</p>
  </div>
</body></html>"""

        msg.attach(MIMEText(text, "plain"))
        msg.attach(MIMEText(html, "html"))

        with smtplib.SMTP(smtp_host, smtp_port, timeout=10) as server:
            server.ehlo()
            server.starttls()
            server.login(smtp_user, smtp_password)
            server.sendmail(smtp_user, notify_email, msg.as_string())

    except Exception as e:
        import logging
        logging.getLogger("macrobandit").warning(f"E-Mail Benachrichtigung fehlgeschlagen: {e}")


@router.post("/register", response_model=schemas.UserOut, status_code=201)
@limiter.limit("5/minute")
def register(request: Request, data: schemas.UserRegister, db: Session = Depends(get_db)):
    if db.query(models.User).filter(models.User.email == data.email).first():
        raise HTTPException(status_code=400, detail="E-Mail bereits registriert")
    if db.query(models.User).filter(models.User.username == data.username).first():
        raise HTTPException(status_code=400, detail="Benutzername bereits vergeben")

    user = models.User(
        email=data.email,
        username=data.username,
        hashed_password=auth.hash_password(data.password),
        is_verified=False
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    # Verifikations-Token erstellen
    verify_token = secrets.token_urlsafe(32)
    verify_expires = datetime.now(timezone.utc) + timedelta(hours=24)
    verify = models.EmailVerificationToken(
        user_id=user.id, token=verify_token, expires_at=verify_expires
    )
    db.add(verify)
    db.commit()

    # E-Mails non-blocking senden
    _executor.submit(send_verification_email, user.username, user.email, verify_token)
    _executor.submit(send_registration_email, user.username, user.email)
    return user


@router.post("/login", response_model=schemas.Token)
@limiter.limit("10/minute")
def login(request: Request, data: schemas.UserLogin, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == data.email).first()
    if not user or not auth.verify_password(data.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="E-Mail oder Passwort falsch")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Konto deaktiviert")
    if not user.is_verified:
        raise HTTPException(status_code=403, detail="E-Mail nicht bestätigt — bitte zuerst deine E-Mail verifizieren")
    return schemas.Token(
        access_token=auth.create_access_token(user.id),
        refresh_token=auth.create_refresh_token(user.id)
    )


@router.post("/refresh", response_model=schemas.Token)
@limiter.limit("10/minute")
def refresh(request: Request, data: schemas.TokenRefresh, db: Session = Depends(get_db)):
    payload = auth.decode_refresh_token_payload(data.refresh_token)
    user_id = payload.get("sub") if payload else None
    if not user_id:
        raise HTTPException(status_code=401, detail="Ungültiger oder abgelaufener Refresh Token")
    user = db.query(models.User).filter(
        models.User.id == int(user_id), models.User.is_active == True
    ).first()
    if not user:
        raise HTTPException(status_code=401, detail="Benutzer nicht gefunden")
    if not auth.verify_token_age(user, payload.get("iat")):
        raise HTTPException(status_code=401, detail="Token nach Passwortänderung ungültig")
    return schemas.Token(
        access_token=auth.create_access_token(user.id),
        refresh_token=auth.create_refresh_token(user.id)
    )


@router.get("/me", response_model=schemas.UserOut)
def me(current_user: models.User = Depends(auth.get_current_user)):
    return current_user


@router.put("/goals", response_model=schemas.UserOut)
def update_goals(
    data: schemas.GoalsUpdate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    current_user.goal_kcal    = data.goal_kcal
    current_user.goal_protein = data.goal_protein
    current_user.goal_carbs   = data.goal_carbs
    current_user.goal_fat     = data.goal_fat
    current_user.goal_fiber   = data.goal_fiber
    db.commit()
    db.refresh(current_user)
    return current_user


@router.post("/forgot-password")
@limiter.limit("3/minute")
def forgot_password(request: Request, data: schemas.ForgotPassword, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == data.email).first()
    # Immer gleiche Antwort — verhindert User-Enumeration
    response = {"message": "Falls die E-Mail existiert, wurde ein Reset-Link gesendet"}
    if not user:
        return response

    # Alte Tokens ungültig machen
    db.query(models.PasswordResetToken).filter(
        models.PasswordResetToken.user_id == user.id,
        models.PasswordResetToken.used == False
    ).update({"used": True})

    token = secrets.token_urlsafe(32)
    expires = datetime.now(timezone.utc) + timedelta(hours=1)
    reset = models.PasswordResetToken(user_id=user.id, token=token, expires_at=expires)
    db.add(reset)
    db.commit()

    reset_url = f"https://macrobandit.at/reset-password?token={token}"

    try:
        smtp_host     = os.getenv("SMTP_HOST")
        smtp_port     = int(os.getenv("SMTP_PORT", 587))
        smtp_user     = os.getenv("SMTP_USER")
        smtp_password = os.getenv("SMTP_PASSWORD")

        if all([smtp_host, smtp_user, smtp_password]):
            msg = MIMEMultipart("alternative")
            msg["Subject"] = "🔑 MacroBandit — Passwort zurücksetzen"
            msg["From"]    = smtp_user
            msg["To"]      = user.email

            text = f"Hallo {user.username},\n\nDu hast eine Passwortzurücksetzung angefordert.\n\nLink: {reset_url}\n\nDer Link ist 1 Stunde gültig.\n\nFalls du das nicht warst, ignoriere diese E-Mail."
            html = f"""
<html><body style="font-family:sans-serif;background:#0f172a;color:#e2e8f0;padding:32px;">
  <div style="max-width:480px;margin:0 auto;background:#1e293b;border-radius:16px;padding:32px;border:1px solid #334155;">
    <h2 style="color:#34d399;margin-top:0;">🔑 Passwort zurücksetzen</h2>
    <p style="color:#94a3b8;">Hallo <strong style="color:#f1f5f9;">{user.username}</strong>,</p>
    <p style="color:#94a3b8;">Du hast eine Passwortzurücksetzung für dein MacroBandit Konto angefordert.</p>
    <div style="text-align:center;margin:32px 0;">
      <a href="{reset_url}" style="background:linear-gradient(to right,#34d399,#22d3ee);color:#0f172a;font-weight:900;padding:14px 32px;border-radius:12px;text-decoration:none;font-size:16px;">
        Passwort zurücksetzen
      </a>
    </div>
    <p style="color:#475569;font-size:12px;">Der Link ist <strong>1 Stunde</strong> gültig.<br>Falls du das nicht warst, ignoriere diese E-Mail.</p>
    <hr style="border-color:#334155;margin:24px 0;">
    <p style="color:#475569;font-size:11px;word-break:break-all;">Link: {reset_url}</p>
  </div>
</body></html>"""

            msg.attach(MIMEText(text, "plain"))
            msg.attach(MIMEText(html, "html"))

            with smtplib.SMTP(smtp_host, smtp_port) as server:
                server.ehlo()
                server.starttls()
                server.login(smtp_user, smtp_password)
                server.sendmail(smtp_user, user.email, msg.as_string())
    except Exception as e:
        import logging
        logging.getLogger("macrobandit").warning(f"Reset E-Mail fehlgeschlagen: {e}")

    return response


@router.get("/verify-email")
@limiter.limit("10/minute")
def verify_email(request: Request, token: str, db: Session = Depends(get_db)):
    record = db.query(models.EmailVerificationToken).filter(
        models.EmailVerificationToken.token == token,
        models.EmailVerificationToken.used == False
    ).first()
    if not record:
        raise HTTPException(status_code=400, detail="Ungültiger oder bereits verwendeter Token")
    if _is_expired(record.expires_at):
        raise HTTPException(status_code=400, detail="Token abgelaufen — bitte neu anfordern")
    user = db.query(models.User).filter(models.User.id == record.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Benutzer nicht gefunden")
    user.is_verified = True
    record.used = True
    db.commit()
    _executor.submit(send_welcome_email, user.username, user.email)
    return {"message": "E-Mail erfolgreich bestätigt"}


@router.post("/resend-verification")
@limiter.limit("3/minute")
def resend_verification(request: Request, current_user: models.User = Depends(auth.get_current_user), db: Session = Depends(get_db)):
    if current_user.is_verified:
        raise HTTPException(status_code=400, detail="E-Mail bereits verifiziert")
    db.query(models.EmailVerificationToken).filter(
        models.EmailVerificationToken.user_id == current_user.id,
        models.EmailVerificationToken.used == False
    ).update({"used": True})
    token = secrets.token_urlsafe(32)
    expires = datetime.now(timezone.utc) + timedelta(hours=24)
    verify = models.EmailVerificationToken(user_id=current_user.id, token=token, expires_at=expires)
    db.add(verify)
    db.commit()
    _executor.submit(send_verification_email, current_user.username, current_user.email, token)
    return {"message": "Verifikations-E-Mail erneut gesendet"}


@router.post("/feedback")
@limiter.limit("3/minute")
def send_feedback(request: Request, data: schemas.FeedbackCreate, current_user: models.User = Depends(auth.get_current_user)):
    def _send():
        try:
            smtp_host     = os.getenv("SMTP_HOST")
            smtp_port     = int(os.getenv("SMTP_PORT", 587))
            smtp_user     = os.getenv("SMTP_USER")
            smtp_password = os.getenv("SMTP_PASSWORD")
            notify_email  = os.getenv("NOTIFY_EMAIL", "trainer@macrobandit.at")
            if not all([smtp_host, smtp_user, smtp_password]):
                return
            from datetime import datetime as dt
            now = dt.now().strftime("%d.%m.%Y um %H:%M Uhr")
            msg = MIMEMultipart("alternative")
            msg["Subject"] = f"💬 MacroBandit Feedback von {current_user.username}"
            msg["From"]    = smtp_user
            msg["To"]      = notify_email
            msg_safe = html_escape(data.message)
            text = f"Feedback von {current_user.username} ({current_user.email})\n\n{data.message}"
            html = f"""
<html><body style="font-family:sans-serif;background:#0f172a;color:#e2e8f0;padding:32px;">
  <div style="max-width:480px;margin:0 auto;background:#1e293b;border-radius:16px;padding:32px;border:1px solid #334155;">
    <h2 style="color:#34d399;margin-top:0;">💬 Neues Feedback</h2>
    <table style="width:100%;border-collapse:collapse;">
      <tr><td style="color:#94a3b8;padding:8px 0;width:140px;">Benutzername</td><td style="color:#f1f5f9;font-weight:bold;">{current_user.username}</td></tr>
      <tr><td style="color:#94a3b8;padding:8px 0;">E-Mail</td><td style="color:#f1f5f9;">{current_user.email}</td></tr>
      <tr><td style="color:#94a3b8;padding:8px 0;">Gesendet am</td><td style="color:#f1f5f9;">{now}</td></tr>
    </table>
    <hr style="border-color:#334155;margin:24px 0;">
    <div style="background:#0f172a;border-radius:12px;padding:16px;color:#f1f5f9;line-height:1.7;white-space:pre-wrap;">{msg_safe}</div>
    <hr style="border-color:#334155;margin:24px 0;">
    <p style="color:#475569;font-size:12px;margin:0;">macrobandit.at</p>
  </div>
</body></html>"""
            msg.attach(MIMEText(text, "plain"))
            msg.attach(MIMEText(html, "html"))
            with smtplib.SMTP(smtp_host, smtp_port, timeout=10) as server:
                server.ehlo(); server.starttls()
                server.login(smtp_user, smtp_password)
                server.sendmail(smtp_user, notify_email, msg.as_string())
        except Exception as e:
            import logging
            logging.getLogger("macrobandit").warning(f"Feedback-Mail fehlgeschlagen: {e}")
    _executor.submit(_send)
    return {"message": "Feedback gesendet — danke!"}


@router.delete("/account")
def delete_account(
    data: schemas.DeleteAccount,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    if not auth.verify_password(data.password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Passwort falsch")
    if current_user.avatar_path:
        try:
            old_avatar = AVATAR_DIR / Path(current_user.avatar_path).name
            if old_avatar.exists():
                old_avatar.unlink()
        except Exception:
            pass
    db.query(models.EmailVerificationToken).filter(models.EmailVerificationToken.user_id == current_user.id).delete()
    db.query(models.PasswordResetToken).filter(models.PasswordResetToken.user_id == current_user.id).delete()
    db.query(models.UserFoodStat).filter(models.UserFoodStat.user_id == current_user.id).delete()
    db.query(models.DailyLog).filter(models.DailyLog.user_id == current_user.id).delete()
    db.query(models.WeightLog).filter(models.WeightLog.user_id == current_user.id).delete()
    db.query(models.FoodItem).filter(models.FoodItem.user_id == current_user.id).delete()
    db.delete(current_user)
    db.commit()
    return {"message": "Konto erfolgreich gelöscht"}


@router.put("/username", response_model=schemas.UserOut)
def change_username(
    data: schemas.UsernameChange,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    existing = db.query(models.User).filter(
        models.User.username == data.username,
        models.User.id != current_user.id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Benutzername bereits vergeben")
    current_user.username = data.username
    db.commit()
    db.refresh(current_user)
    return current_user


@router.post("/reset-password")
@limiter.limit("10/minute")
def reset_password(request: Request, data: schemas.ResetPassword, db: Session = Depends(get_db)):
    reset = db.query(models.PasswordResetToken).filter(
        models.PasswordResetToken.token == data.token,
        models.PasswordResetToken.used == False
    ).first()

    if not reset:
        raise HTTPException(status_code=400, detail="Ungültiger oder bereits verwendeter Token")

    if _is_expired(reset.expires_at):
        raise HTTPException(status_code=400, detail="Token abgelaufen — bitte neu anfordern")

    user = db.query(models.User).filter(models.User.id == reset.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Benutzer nicht gefunden")

    user.hashed_password = auth.hash_password(data.new_password)
    reset.used = True
    db.commit()

    return {"message": "Passwort erfolgreich geändert"}


@router.post("/avatar", response_model=schemas.UserOut)
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    # Typ prüfen
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=400, detail="Nur JPG, PNG oder WEBP erlaubt")

    # Größe prüfen
    contents = await file.read()
    if len(contents) > MAX_SIZE_BYTES:
        raise HTTPException(status_code=400, detail="Datei zu groß (max. 5MB)")

    # Bild verarbeiten mit Pillow
    try:
        from PIL import Image
        import io

        img = Image.open(io.BytesIO(contents))

        # EXIF-Rotation korrigieren
        try:
            from PIL.ExifTags import TAGS
            exif = img._getexif()
            if exif:
                for tag, val in exif.items():
                    if TAGS.get(tag) == "Orientation":
                        if val == 3:   img = img.rotate(180, expand=True)
                        elif val == 6: img = img.rotate(270, expand=True)
                        elif val == 8: img = img.rotate(90,  expand=True)
        except Exception:
            pass

        # Quadratisch zuschneiden (zentriert)
        w, h = img.size
        size = min(w, h)
        left   = (w - size) // 2
        top    = (h - size) // 2
        img = img.crop((left, top, left + size, top + size))

        # Auf 200x200 skalieren
        img = img.resize((200, 200), Image.LANCZOS)

        # Als JPEG speichern
        if img.mode in ("RGBA", "P"):
            img = img.convert("RGB")

        filename = f"{current_user.id}_{uuid.uuid4().hex[:8]}.jpg"
        filepath = AVATAR_DIR / filename

        # Altes Avatar löschen
        if current_user.avatar_path:
            old = AVATAR_DIR / Path(current_user.avatar_path).name
            if old.exists():
                old.unlink()

        img.save(filepath, "JPEG", quality=85, optimize=True)

    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Bild konnte nicht verarbeitet werden: {e}")

    # Pfad in DB speichern
    current_user.avatar_path = f"/uploads/avatars/{filename}"
    db.commit()
    db.refresh(current_user)
    return current_user


@router.put("/password")
def change_password(
    data: schemas.PasswordChange,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    if not auth.verify_password(data.current_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Aktuelles Passwort ist falsch")
    from datetime import datetime, timezone
    current_user.hashed_password = auth.hash_password(data.new_password)
    current_user.password_changed_at = datetime.now(timezone.utc)
    db.commit()
    return {"message": "Passwort erfolgreich geändert"}


@router.delete("/avatar", response_model=schemas.UserOut)
def delete_avatar(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.avatar_path:
        old = AVATAR_DIR / Path(current_user.avatar_path).name
        if old.exists():
            old.unlink()
        current_user.avatar_path = None
        db.commit()
        db.refresh(current_user)
    return current_user


@router.get("/export")
def export_data(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    import csv, io
    from fastapi.responses import StreamingResponse
    from datetime import datetime as dt

    output = io.StringIO()
    writer = csv.writer(output)

    writer.writerow(["=== BENUTZERDATEN ==="])
    writer.writerow(["Benutzername", "E-Mail", "Registriert am", "Kalorienziel", "Proteinziel", "KH-Ziel", "Fettziel", "Ballaststoffziel"])
    writer.writerow([_csv_safe(current_user.username), _csv_safe(current_user.email), current_user.created_at.strftime("%d.%m.%Y %H:%M") if current_user.created_at else "", current_user.goal_kcal, current_user.goal_protein, current_user.goal_carbs, current_user.goal_fat, current_user.goal_fiber])

    writer.writerow([])
    writer.writerow(["=== ERNAEHRUNGSTAGEBUCH ==="])
    writer.writerow(["Datum", "Lebensmittel", "Menge (g)", "Kalorien", "Protein (g)", "Kohlenhydrate (g)", "Fett (g)", "Ballaststoffe (g)"])
    logs = db.query(models.DailyLog).filter(models.DailyLog.user_id == current_user.id).order_by(models.DailyLog.date.desc()).all()
    for log in logs:
        writer.writerow([log.date.strftime("%d.%m.%Y") if log.date else "", _csv_safe(log.food_name or ""), log.amount_grams or 0, log.calories or 0, log.protein or 0, log.carbs or 0, log.fat or 0, log.fiber or 0])

    writer.writerow([])
    writer.writerow(["=== GEWICHTSVERLAUF ==="])
    writer.writerow(["Datum", "Gewicht (kg)"])
    weights = db.query(models.WeightLog).filter(models.WeightLog.user_id == current_user.id).order_by(models.WeightLog.date.desc()).all()
    for w in weights:
        writer.writerow([w.date.strftime("%d.%m.%Y") if w.date else "", w.weight_kg])

    output.seek(0)
    filename = f"macrobandit_export_{dt.now().strftime('%Y%m%d')}.csv"
    return StreamingResponse(iter([output.getvalue()]), media_type="text/csv; charset=utf-8", headers={"Content-Disposition": f"attachment; filename={filename}"})


@router.put("/reminder")
def set_reminder(
    data: schemas.ReminderUpdate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    current_user.reminder_time = data.reminder_time
    db.commit()
    return {"message": "Erinnerung gespeichert", "reminder_time": data.reminder_time}

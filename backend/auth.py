from datetime import datetime, timedelta, timezone
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
import os

from database import get_db
import models

SECRET_KEY         = os.getenv("SECRET_KEY")
REFRESH_SECRET_KEY = os.getenv("REFRESH_SECRET_KEY")
if not SECRET_KEY or not REFRESH_SECRET_KEY:
    raise RuntimeError(
        "SECRET_KEY und REFRESH_SECRET_KEY müssen gesetzt sein — "
        "kein unsicherer Default-Schlüssel erlaubt."
    )
ALGORITHM                    = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES  = 60  # kurzlebig; Frontend erneuert per Refresh-Token bei 401
REFRESH_TOKEN_EXPIRE_DAYS    = 30

pwd_context   = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(user_id: int) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode(
        {"sub": str(user_id), "exp": expire, "iat": datetime.now(timezone.utc).timestamp(), "type": "access"},
        SECRET_KEY, algorithm=ALGORITHM
    )

def create_refresh_token(user_id: int) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    return jwt.encode(
        {"sub": str(user_id), "exp": expire, "iat": datetime.now(timezone.utc).timestamp(), "type": "refresh"},
        REFRESH_SECRET_KEY, algorithm=ALGORITHM
    )

def decode_access_token_payload(token: str) -> Optional[dict]:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != "access":
            return None
        return payload
    except JWTError:
        return None

def decode_refresh_token_payload(token: str) -> Optional[dict]:
    try:
        payload = jwt.decode(token, REFRESH_SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != "refresh":
            return None
        return payload
    except JWTError:
        return None

def decode_access_token(token: str) -> Optional[int]:
    payload = decode_access_token_payload(token)
    user_id = payload.get("sub") if payload else None
    return int(user_id) if user_id else None

def decode_refresh_token(token: str) -> Optional[int]:
    payload = decode_refresh_token_payload(token)
    user_id = payload.get("sub") if payload else None
    return int(user_id) if user_id else None


def verify_token_age(user, issued_at: float) -> bool:
    """Prüft ob Token vor Passwortänderung ausgestellt wurde."""
    if user.password_changed_at and issued_at:
        from datetime import timezone
        changed = user.password_changed_at.replace(tzinfo=timezone.utc).timestamp()
        if issued_at < changed:
            return False
    return True


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> models.User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = decode_access_token_payload(token)
    user_id = payload.get("sub") if payload else None
    if not user_id:
        raise credentials_exception

    user = db.query(models.User).filter(
        models.User.id == int(user_id),
        models.User.is_active == True
    ).first()

    if user is None:
        raise credentials_exception

    # Token vor einer Passwortänderung ausgestellt → ungültig
    if not verify_token_age(user, payload.get("iat")):
        raise credentials_exception
    return user

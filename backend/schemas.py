from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
from datetime import datetime, date


class UserRegister(BaseModel):
    email: EmailStr
    username: str
    password: str

    @field_validator("username")
    @classmethod
    def username_valid(cls, v):
        v = v.strip()
        if len(v) < 3 or len(v) > 50:
            raise ValueError("Username muss 3–50 Zeichen lang sein")
        if not v.replace("_", "").replace("-", "").isalnum():
            raise ValueError("Username darf nur Buchstaben, Zahlen, _ und - enthalten")
        return v

    @field_validator("password")
    @classmethod
    def password_strong(cls, v):
        if len(v) < 8:
            raise ValueError("Passwort muss mindestens 8 Zeichen lang sein")
        if not any(c.isupper() for c in v):
            raise ValueError("Passwort muss mindestens einen Großbuchstaben enthalten")
        if not any(c.islower() for c in v):
            raise ValueError("Passwort muss mindestens einen Kleinbuchstaben enthalten")
        if not any(c.isdigit() for c in v):
            raise ValueError("Passwort muss mindestens eine Zahl enthalten")
        return v


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserOut(BaseModel):
    id:           int
    email:        str
    username:     str
    is_active:    bool
    created_at:   datetime
    avatar_path:  Optional[str] = None
    goal_kcal:    int
    goal_protein: int
    goal_carbs:   int
    goal_fat:     int
    goal_fiber:   int
    is_verified:  bool
    is_admin:     bool
    is_family_member: bool = False

    class Config:
        from_attributes = True


class GoalsUpdate(BaseModel):
    goal_kcal:    int
    goal_protein: int
    goal_carbs:   int
    goal_fat:     int
    goal_fiber:   int


class Token(BaseModel):
    access_token:  str
    refresh_token: str
    token_type:    str = "bearer"


class TokenRefresh(BaseModel):
    refresh_token: str


class ForgotPassword(BaseModel):
    email: EmailStr


class ResetPassword(BaseModel):
    token: str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def password_strong(cls, v):
        if len(v) < 8:
            raise ValueError("Passwort muss mindestens 8 Zeichen lang sein")
        if not any(c.isupper() for c in v):
            raise ValueError("Passwort muss mindestens einen Großbuchstaben enthalten")
        if not any(c.islower() for c in v):
            raise ValueError("Passwort muss mindestens einen Kleinbuchstaben enthalten")
        if not any(c.isdigit() for c in v):
            raise ValueError("Passwort muss mindestens eine Zahl enthalten")
        return v


class PasswordChange(BaseModel):
    current_password: str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def password_strong(cls, v):
        if len(v) < 8:
            raise ValueError("Neues Passwort muss mindestens 8 Zeichen lang sein")
        return v


class UsernameChange(BaseModel):
    username: str

    @field_validator("username")
    @classmethod
    def username_valid(cls, v):
        v = v.strip()
        if len(v) < 3 or len(v) > 50:
            raise ValueError("Username muss 3–50 Zeichen lang sein")
        if not v.replace("_", "").replace("-", "").isalnum():
            raise ValueError("Username darf nur Buchstaben, Zahlen, _ und - enthalten")
        return v


class FeedbackCreate(BaseModel):
    message: str

    @field_validator("message")
    @classmethod
    def message_not_empty(cls, v):
        if len(v.strip()) < 5:
            raise ValueError("Feedback muss mindestens 5 Zeichen lang sein")
        if len(v) > 2000:
            raise ValueError("Feedback darf maximal 2000 Zeichen lang sein")
        return v.strip()


class DeleteAccount(BaseModel):
    password: str


class ReminderUpdate(BaseModel):
    reminder_time: Optional[str] = None

    @field_validator("reminder_time")
    @classmethod
    def valid_time(cls, v):
        if v is None or v == "":
            return None
        import re
        if not re.match(r"^\d{2}:\d{2}$", v):
            raise ValueError("Format muss HH:MM sein")
        h, m = int(v[:2]), int(v[3:])
        if not (0 <= h <= 23 and 0 <= m <= 59):
            raise ValueError("Ungültige Uhrzeit")
        return v


class FoodItemCreate(BaseModel):
    name:              str = Field(..., min_length=1, max_length=255)
    brand:             Optional[str]   = Field(None, max_length=255)
    calories_per_100g: Optional[float] = None
    protein_per_100g:  Optional[float] = None
    carbs_per_100g:    Optional[float] = None
    fat_per_100g:      Optional[float] = None
    fiber_per_100g:    Optional[float] = None
    portion_label:     Optional[str]   = Field(None, max_length=50)
    portion_size_g:    Optional[float] = None


class FoodItemOut(BaseModel):
    id:                int
    user_id:           Optional[int]   = None
    name:              str
    brand:             Optional[str]   = None
    calories_per_100g: Optional[float] = None
    protein_per_100g:  Optional[float] = None
    carbs_per_100g:    Optional[float] = None
    fat_per_100g:      Optional[float] = None
    fiber_per_100g:    Optional[float] = None
    portion_label:     Optional[str]   = None
    portion_size_g:    Optional[float] = None
    use_count:         Optional[int]   = 0
    is_family:         Optional[bool]  = False

    class Config:
        from_attributes = True


class LogCreate(BaseModel):
    food_item_id: int
    amount_grams: float

    @field_validator("amount_grams")
    @classmethod
    def amount_positive(cls, v):
        if v <= 0:
            raise ValueError("Menge muss größer als 0 sein")
        return v


class LogOut(BaseModel):
    id:           int
    food_item_id: Optional[int] = None
    food_name:    str
    amount_grams: float
    calories:     float
    protein:      float
    carbs:        float
    fat:          float
    fiber:        float
    created_at:   datetime
    date:         date

    class Config:
        from_attributes = True


class DailyTotals(BaseModel):
    calories: float
    protein:  float
    carbs:    float
    fat:      float
    fiber:    float
    entries:  int


class DayCalories(BaseModel):
    date:         date
    day_name:     str
    calories:     float
    goal_reached: bool


class WeeklyStats(BaseModel):
    week_start:   date
    week_end:     date
    days:         list[DayCalories]
    weekly_total: float
    weekly_goal:  float
    avg_daily:    float


class ReferenceFoodOut(BaseModel):
    """Treffer aus dem BLS (code) oder aus Open Food Facts (barcode) — noch kein eigenes Lebensmittel."""
    code:              str
    name:              str
    brand:             Optional[str]   = None
    calories_per_100g: Optional[float] = None
    protein_per_100g:  Optional[float] = None
    carbs_per_100g:    Optional[float] = None
    fat_per_100g:      Optional[float] = None
    fiber_per_100g:    Optional[float] = None
    source:            str

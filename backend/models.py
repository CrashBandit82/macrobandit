from sqlalchemy import Column, Integer, String, Float, DateTime, Date, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    avatar_path  = Column(String(500), nullable=True)
    is_verified  = Column(Boolean, default=False)
    is_admin     = Column(Boolean, default=False)
    is_family_member = Column(Boolean, default=False, nullable=False, server_default="false")

    goal_kcal    = Column(Integer, default=2000)
    goal_protein = Column(Integer, default=150)
    goal_carbs   = Column(Integer, default=250)
    goal_fat     = Column(Integer, default=65)
    goal_fiber   = Column(Integer, default=30)

    # Für TDEE Rechner
    gender       = Column(String(10), nullable=True)   # "male" | "female"
    age          = Column(Integer, nullable=True)
    height_cm    = Column(Integer, nullable=True)
    reminder_time = Column(String(5), nullable=True)  # Format: "18:00"
    password_changed_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=True)

    food_items   = relationship("FoodItem", back_populates="owner")
    daily_logs   = relationship("DailyLog", back_populates="user")
    food_stats   = relationship("UserFoodStat", back_populates="user")
    weight_logs  = relationship("WeightLog", back_populates="user")


class PasswordResetToken(Base):
    __tablename__ = "password_reset_tokens"

    id         = Column(Integer, primary_key=True, index=True)
    user_id    = Column(Integer, ForeignKey("users.id"), nullable=False)
    token      = Column(String(64), unique=True, index=True, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    used       = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class EmailVerificationToken(Base):
    __tablename__ = "email_verification_tokens"

    id         = Column(Integer, primary_key=True, index=True)
    user_id    = Column(Integer, ForeignKey("users.id"), nullable=False)
    token      = Column(String(64), unique=True, index=True, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    used       = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class WeightLog(Base):
    __tablename__ = "weight_logs"

    id         = Column(Integer, primary_key=True, index=True)
    user_id    = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    weight_kg  = Column(Float, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    date       = Column(Date, index=True)

    user = relationship("User", back_populates="weight_logs")



class MealTemplate(Base):
    __tablename__ = "meal_templates"

    id         = Column(Integer, primary_key=True, index=True)
    user_id    = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    name       = Column(String(255), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user  = relationship("User", backref="meal_templates")
    items = relationship("MealTemplateItem", back_populates="template", cascade="all, delete-orphan")


class MealTemplateItem(Base):
    __tablename__ = "meal_template_items"

    id           = Column(Integer, primary_key=True, index=True)
    template_id  = Column(Integer, ForeignKey("meal_templates.id"), nullable=False, index=True)
    food_item_id = Column(Integer, ForeignKey("food_items.id"), nullable=False)
    amount_grams = Column(Float, nullable=False)

    template  = relationship("MealTemplate", back_populates="items")
    food_item = relationship("FoodItem")


class FoodItem(Base):
    __tablename__ = "food_items"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    name = Column(String(255), nullable=False, index=True)
    brand = Column(String(255), nullable=True)
    calories_per_100g = Column(Float, nullable=True)
    protein_per_100g  = Column(Float, nullable=True)
    carbs_per_100g    = Column(Float, nullable=True)
    fat_per_100g      = Column(Float, nullable=True)
    fiber_per_100g    = Column(Float, nullable=True)
    portion_label     = Column(String(50), nullable=True)   # z.B. "1 Stück"
    portion_size_g    = Column(Float, nullable=True)         # z.B. 150
    is_family  = Column(Boolean, default=False, nullable=False, server_default="false")
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    owner      = relationship("User", back_populates="food_items")
    daily_logs = relationship("DailyLog", back_populates="food_item")
    user_stats = relationship("UserFoodStat", back_populates="food_item")


class UserFoodStat(Base):
    __tablename__ = "user_food_stats"

    id           = Column(Integer, primary_key=True, index=True)
    user_id      = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    food_item_id = Column(Integer, ForeignKey("food_items.id"), nullable=False, index=True)
    use_count    = Column(Integer, default=1)
    last_used    = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user      = relationship("User", back_populates="food_stats")
    food_item = relationship("FoodItem", back_populates="user_stats")


class DailyLog(Base):
    __tablename__ = "daily_logs"

    id           = Column(Integer, primary_key=True, index=True)
    user_id      = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    food_item_id = Column(Integer, ForeignKey("food_items.id"), nullable=True)
    food_name    = Column(String(255))
    amount_grams = Column(Float)
    calories     = Column(Float)
    protein      = Column(Float)
    carbs        = Column(Float)
    fat          = Column(Float)
    fiber        = Column(Float)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())
    date         = Column(Date, index=True)

    user      = relationship("User", back_populates="daily_logs")
    food_item = relationship("FoodItem", back_populates="daily_logs")


class PushSubscription(Base):
    __tablename__ = "push_subscriptions"

    id         = Column(Integer, primary_key=True, index=True)
    user_id    = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    endpoint   = Column(String(500), unique=True, nullable=False)
    p256dh     = Column(String(200), nullable=False)
    auth       = Column(String(100), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", backref="push_subscriptions")


class ReferenceFood(Base):
    """Nährwert-Referenz (Bundeslebensmittelschlüssel BLS 4.0, Max Rubner-Institut) — eigene, schreibgeschützte
    Tabelle; wird nur von import_bls.py befüllt. Nutzer-Lebensmittel (food_items) bleiben davon unberührt:
    wählt jemand einen BLS-Eintrag, entsteht eine NEUE Zeile in food_items (brand "BLS 4.0")."""
    __tablename__ = "reference_foods"

    code              = Column(String(16), primary_key=True)      # BLS-Code, z. B. "M111000"
    name              = Column(String(255), nullable=False, index=True)
    calories_per_100g = Column(Float, nullable=True)
    protein_per_100g  = Column(Float, nullable=True)
    carbs_per_100g    = Column(Float, nullable=True)
    fat_per_100g      = Column(Float, nullable=True)
    fiber_per_100g    = Column(Float, nullable=True)
    source            = Column(String(50), nullable=False, default="BLS 4.0")

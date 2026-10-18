from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from pathlib import Path
import logging
import logging.handlers
import os

from database import engine
import models
from routers import auth, foods, logs, stats, weight, admin, templates, push, reference

# ── Logging ───────────────────────────────────────────────────────────────────

LOG_DIR = Path("/var/log/macrobandit")
LOG_DIR.mkdir(parents=True, exist_ok=True)

def setup_logging():
    fmt = logging.Formatter(
        "%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )

    # Rotating File Handler — max 10MB, 5 Backups
    file_handler = logging.handlers.RotatingFileHandler(
        LOG_DIR / "app.log",
        maxBytes=10 * 1024 * 1024,
        backupCount=5,
        encoding="utf-8"
    )
    file_handler.setFormatter(fmt)
    file_handler.setLevel(logging.INFO)

    # Error-Log extra
    error_handler = logging.handlers.RotatingFileHandler(
        LOG_DIR / "error.log",
        maxBytes=5 * 1024 * 1024,
        backupCount=3,
        encoding="utf-8"
    )
    error_handler.setFormatter(fmt)
    error_handler.setLevel(logging.ERROR)

    # Console
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(fmt)
    console_handler.setLevel(logging.INFO)

    root = logging.getLogger()
    root.setLevel(logging.INFO)
    root.addHandler(file_handler)
    root.addHandler(error_handler)
    root.addHandler(console_handler)

setup_logging()
logger = logging.getLogger("macrobandit")
logger.info("MacroBandit Backend starting...")

# ── DB Tables ─────────────────────────────────────────────────────────────────

models.Base.metadata.create_all(bind=engine)

# ── Rate Limiter ──────────────────────────────────────────────────────────────

limiter = Limiter(
    key_func=get_remote_address,
    default_limits=["50/minute"],        # Global: max 100 Requests/min pro IP
    storage_uri="memory://"
)

# ── App ───────────────────────────────────────────────────────────────────────

app = FastAPI(
    title="MacroBandit API",
    version="2.0.0",
    openapi_url=None,
    docs_url="/api/docs",
    redoc_url=None
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)  # aktiviert die globalen default_limits

# ── Request Logging Middleware ────────────────────────────────────────────────

@app.middleware("http")
async def log_requests(request: Request, call_next):
    response = await call_next(request)
    # Nur Fehler und wichtige Requests loggen (nicht jeden GET)
    if response.status_code >= 400:
        logger.warning(
            f"{request.method} {request.url.path} → {response.status_code} "
            f"[{request.client.host if request.client else 'unknown'}]"
        )
    elif request.method in ("POST", "PUT", "DELETE"):
        logger.info(
            f"{request.method} {request.url.path} → {response.status_code} "
            f"[{request.client.host if request.client else 'unknown'}]"
        )
    return response

# ── CORS ──────────────────────────────────────────────────────────────────────

ALLOWED_ORIGINS = os.getenv(
    "ALLOWED_ORIGINS",
    "http://localhost,http://localhost:5173,https://macrobandit.at,https://www.macrobandit.at"
).split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Static Files ──────────────────────────────────────────────────────────────

UPLOAD_DIR = Path("/opt/macrobandit/uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")

# ── Routers ───────────────────────────────────────────────────────────────────

app.include_router(auth.router)
app.include_router(foods.router)
app.include_router(reference.reference_router)
app.include_router(reference.online_router)
app.include_router(logs.router)
app.include_router(stats.router)
app.include_router(weight.router)
app.include_router(admin.router)
app.include_router(templates.router)
app.include_router(push.router)


# ── Health ────────────────────────────────────────────────────────────────────

@app.get("/api/health")
def health():
    return {"status": "ok", "version": "2.0.0"}


# ── Seed ─────────────────────────────────────────────────────────────────────

@app.on_event("startup")
def seed_global_foods():
    from database import SessionLocal
    db = SessionLocal()
    try:
        count = db.query(models.FoodItem).filter(models.FoodItem.user_id == None).count()
        if count == 0:
            defaults = [
                ("Hähnchenbrustfilet",        None, 165,  31.0,  0.0,  3.6,  0.0),
                ("Eier (Hühnerei)",           None, 155,  13.0,  1.1, 11.0,  0.0),
                ("Haferflocken",              None, 370,  13.0, 58.0,  7.0,  9.7),
                ("Thunfisch (Dose, Wasser)",  None, 116,  26.0,  0.0,  1.0,  0.0),
                ("Lachs",                     None, 208,  20.0,  0.0, 13.0,  0.0),
                ("Magerquark",                None,  67,  12.0,  4.0,  0.2,  0.0),
                ("Griechischer Joghurt (0%)", None,  59,  10.0,  3.6,  0.4,  0.0),
                ("Vollkornbrot",              None, 247,   8.5, 41.0,  3.5,  7.5),
                ("Reis (gekocht)",            None, 130,   2.7, 28.0,  0.3,  0.4),
                ("Nudeln (gekocht)",          None, 157,   5.8, 31.0,  0.9,  1.8),
                ("Süßkartoffel",              None,  86,   1.6, 20.0,  0.1,  3.0),
                ("Brokkoli",                  None,  34,   2.8,  7.0,  0.4,  2.6),
                ("Banane",                    None,  89,   1.1, 23.0,  0.3,  2.6),
                ("Mandeln",                   None, 579,  21.0, 22.0, 50.0, 12.5),
                ("Olivenöl",                  None, 884,   0.0,  0.0,100.0,  0.0),
                ("Whey Protein",              None, 400,  80.0,  8.0,  5.0,  0.0),
                ("Linsen (gekocht)",          None, 116,   9.0, 20.0,  0.4,  7.9),
                ("Kichererbsen (gekocht)",    None, 164,   8.9, 27.0,  2.6,  7.6),
                ("Spinat",                    None,  23,   2.9,  3.6,  0.4,  2.2),
                ("Avocado",                   None, 160,   2.0,  9.0, 15.0,  7.0),
            ]
            for d in defaults:
                db.add(models.FoodItem(
                    name=d[0], brand=d[1],
                    calories_per_100g=d[2], protein_per_100g=d[3],
                    carbs_per_100g=d[4], fat_per_100g=d[5], fiber_per_100g=d[6],
                    user_id=None
                ))
            db.commit()
            logger.info(f"Seeded {len(defaults)} globale Lebensmittel")
    finally:
        db.close()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from .database.connection import create_tables
from .api.auth import router as auth_router
from .api.matches import router as matches_router
from .api.routes import sub_router, fav_router, notif_router, pred_router
from .api.cricket import series_router, players_router, rankings_router
from .utils.config import get_settings

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    create_tables()
    yield
    # Shutdown


app = FastAPI(
    title="YS SCORE 11 API",
    description="Backend API for YS SCORE 11 Cricket App by Young Storms",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.app_env == "development" else None,
    redoc_url=None,
)

# CORS
_is_dev = settings.app_env == "development"
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in settings.allowed_origins.split(",")],
    allow_origin_regex=r"http://localhost:\d+" if _is_dev else None,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
API_PREFIX = "/api/v1"
app.include_router(auth_router, prefix=API_PREFIX)
app.include_router(matches_router, prefix=API_PREFIX)
app.include_router(sub_router, prefix=API_PREFIX)
app.include_router(fav_router, prefix=API_PREFIX)
app.include_router(notif_router, prefix=API_PREFIX)
app.include_router(pred_router, prefix=API_PREFIX)
app.include_router(series_router, prefix=API_PREFIX)
app.include_router(players_router, prefix=API_PREFIX)
app.include_router(rankings_router, prefix=API_PREFIX)


@app.get("/health")
def health():
    return {"status": "ok", "app": "YS SCORE 11", "version": "1.0.0"}

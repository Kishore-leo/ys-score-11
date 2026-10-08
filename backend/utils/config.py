from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    database_url: str = "postgresql://user:password@localhost:5432/ys_score_11"
    secret_key: str = "change-this-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 10080  # 7 days

    cricket_api_key: str = ""
    cricket_api_base_url: str = "https://api.cricketdata.org/api/v1"

    firebase_credentials_path: str = "./firebase-credentials.json"

    google_play_package_name: str = "com.youngstorms.ys_score_11"
    apple_bundle_id: str = "com.youngstorms.ysscore11"
    apple_shared_secret: str = ""

    app_env: str = "development"
    allowed_origins: str = "http://localhost:3000"

    class Config:
        env_file = ".env"


@lru_cache
def get_settings() -> Settings:
    return Settings()

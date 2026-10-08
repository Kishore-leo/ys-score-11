from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional, List, Dict, Any
from datetime import datetime


# ── Auth ──────────────────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    email_or_mobile: str
    password: str


class RegisterRequest(BaseModel):
    name: str
    email: EmailStr
    password: str
    mobile: Optional[str] = None

    @field_validator("password")
    @classmethod
    def password_min_length(cls, v):
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters")
        return v


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    mobile: Optional[str] = None
    avatar_url: Optional[str] = None
    is_premium: bool = False
    premium_expiry: Optional[datetime] = None
    token: str

    model_config = {"from_attributes": True}


# ── Subscription ──────────────────────────────────────────────────────────────

class VerifySubscriptionRequest(BaseModel):
    purchase_token: str
    product_id: str
    platform: Optional[str] = None  # android / ios


class SubscriptionStatusResponse(BaseModel):
    is_active: bool
    expires_at: Optional[datetime] = None
    product_id: Optional[str] = None


# ── Favorites ─────────────────────────────────────────────────────────────────

class FavoriteRequest(BaseModel):
    type: str  # team, player, series
    item_id: str


# ── FCM ───────────────────────────────────────────────────────────────────────

class FcmTokenRequest(BaseModel):
    token: str


# ── Match ─────────────────────────────────────────────────────────────────────

class TeamScoreSchema(BaseModel):
    team_id: str
    team_name: str
    team_short_name: str
    logo_url: Optional[str] = None
    runs: Optional[int] = None
    wickets: Optional[int] = None
    overs: Optional[float] = None
    is_all_out: Optional[bool] = None


class MatchSchema(BaseModel):
    id: str
    match_type: str
    status: str
    team1: TeamScoreSchema
    team2: TeamScoreSchema
    venue: str
    match_date: datetime
    result: Optional[str] = None
    toss_winner: Optional[str] = None
    toss_decision: Optional[str] = None
    series_id: Optional[str] = None
    series_name: Optional[str] = None
    current_run_rate: Optional[float] = None
    required_run_rate: Optional[float] = None
    target_runs: Optional[int] = None
    current_innings: Optional[str] = None


# ── Prediction ────────────────────────────────────────────────────────────────

class PredictionSchema(BaseModel):
    match_id: str
    team1_id: str
    team1_name: str
    team2_id: str
    team2_name: str
    team1_win_probability: float
    team2_win_probability: float
    predicted_winner: str
    confidence: float
    explanation: str
    factors: Dict[str, Any]

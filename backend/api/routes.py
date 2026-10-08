from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from ..database.connection import get_db
from ..api.dependencies import get_current_user, get_premium_user
from ..models.db_models import User, Favorite, Notification, Subscription
from ..schemas.schemas import (
    VerifySubscriptionRequest, SubscriptionStatusResponse,
    FavoriteRequest, FcmTokenRequest, PredictionSchema
)
from ..services.subscription_service import verify_google_play_purchase, verify_apple_purchase, activate_subscription

# ── Subscriptions ─────────────────────────────────────────────────────────────

sub_router = APIRouter(prefix="/subscriptions", tags=["subscriptions"])


@sub_router.post("/verify")
async def verify_subscription(
    body: VerifySubscriptionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    platform = body.platform or "android"
    try:
        if platform == "android":
            result = await verify_google_play_purchase(body.purchase_token, body.product_id)
        else:
            result = await verify_apple_purchase(body.purchase_token)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    if not result["success"]:
        raise HTTPException(status_code=400, detail="Purchase verification failed")

    activate_subscription(
        db, current_user.id, body.purchase_token, body.product_id,
        platform, result["expires_at"]
    )
    return {"success": True, "expires_at": result["expires_at"]}


@sub_router.get("/status", response_model=SubscriptionStatusResponse)
def get_subscription_status(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    sub = db.query(Subscription).filter(Subscription.user_id == current_user.id).first()
    if not sub:
        return SubscriptionStatusResponse(is_active=False)
    is_active = sub.is_active and sub.expires_at and sub.expires_at > datetime.now(timezone.utc)
    return SubscriptionStatusResponse(
        is_active=bool(is_active),
        expires_at=sub.expires_at,
        product_id=sub.product_id,
    )


# ── Favorites ─────────────────────────────────────────────────────────────────

fav_router = APIRouter(prefix="/favorites", tags=["favorites"])


@fav_router.get("")
def get_favorites(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    favs = db.query(Favorite).filter(Favorite.user_id == current_user.id).all()
    result: dict = {"team": [], "player": [], "series": []}
    for f in favs:
        if f.item_type in result:
            result[f.item_type].append(f.item_id)
    return result


@fav_router.post("")
def add_favorite(
    body: FavoriteRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    existing = db.query(Favorite).filter(
        Favorite.user_id == current_user.id,
        Favorite.item_type == body.type,
        Favorite.item_id == body.item_id,
    ).first()
    if existing:
        return {"message": "Already in favorites"}
    fav = Favorite(user_id=current_user.id, item_type=body.type, item_id=body.item_id)
    db.add(fav)
    db.commit()
    return {"message": "Added to favorites"}


@fav_router.delete("")
def remove_favorite(
    body: FavoriteRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    db.query(Favorite).filter(
        Favorite.user_id == current_user.id,
        Favorite.item_type == body.type,
        Favorite.item_id == body.item_id,
    ).delete()
    db.commit()
    return {"message": "Removed from favorites"}


# ── Notifications ─────────────────────────────────────────────────────────────

notif_router = APIRouter(prefix="/notifications", tags=["notifications"])


@notif_router.post("/fcm-token")
def update_fcm_token(
    body: FcmTokenRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    current_user.fcm_token = body.token
    db.commit()
    return {"message": "FCM token updated"}


@notif_router.get("")
def get_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    notifs = (
        db.query(Notification)
        .filter(Notification.user_id == current_user.id)
        .order_by(Notification.created_at.desc())
        .limit(50)
        .all()
    )
    return notifs


# ── Predictions ───────────────────────────────────────────────────────────────

pred_router = APIRouter(prefix="/predictions", tags=["predictions"])


@pred_router.get("/{match_id}", response_model=PredictionSchema)
async def get_prediction(
    match_id: str,
    premium_user: User = Depends(get_premium_user),
    db: Session = Depends(get_db),
):
    """AI match prediction — premium only."""
    from ..ml.predictor import get_prediction_for_match
    result = await get_prediction_for_match(match_id, db)
    if not result:
        raise HTTPException(status_code=404, detail="Prediction not available for this match")
    return result

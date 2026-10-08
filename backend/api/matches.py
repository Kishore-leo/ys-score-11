from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from ..database.connection import get_db
from ..api.dependencies import get_current_user, get_premium_user
from ..models.db_models import User, Match
from ..services import cricket_data_service
from ..ml.predictor import get_prediction_for_match

router = APIRouter(prefix="/matches", tags=["matches"])


@router.get("/live")
async def get_live_matches(current_user: User = Depends(get_current_user)):
    """Live matches — basic info available to all users."""
    try:
        return await cricket_data_service.get_live_matches()
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Cricket data unavailable: {str(e)}")


@router.get("/upcoming")
async def get_upcoming_matches(current_user: User = Depends(get_current_user)):
    try:
        return await cricket_data_service.get_upcoming_matches()
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))


@router.get("/completed")
async def get_completed_matches(current_user: User = Depends(get_current_user)):
    try:
        return await cricket_data_service.get_completed_matches()
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))


@router.get("/{match_id}/live")
async def get_live_match_detail(
    match_id: str,
    premium_user: User = Depends(get_premium_user),  # Premium only
):
    """Full live scorecard — premium only."""
    try:
        return await cricket_data_service.get_match_scorecard(match_id)
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from ..database.connection import get_db
from ..services.auth_service import decode_token, get_user_by_id
from ..models.db_models import User

bearer_scheme = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    token = credentials.credentials
    user_id = decode_token(token)
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")
    user = get_user_by_id(db, user_id)
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    return user


def get_premium_user(user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> User:
    from ..services.auth_service import is_premium
    if not is_premium(db, user.id):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Premium subscription required")
    return user

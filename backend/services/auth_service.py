from datetime import datetime, timedelta, timezone
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session
from ..models.db_models import User, Subscription
from ..utils.config import get_settings

settings = get_settings()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.access_token_expire_minutes)
    return jwt.encode(
        {"sub": user_id, "exp": expire},
        settings.secret_key,
        algorithm=settings.algorithm,
    )


def decode_token(token: str) -> Optional[str]:
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        return payload.get("sub")
    except JWTError:
        return None


def get_user_by_email_or_mobile(db: Session, email_or_mobile: str) -> Optional[User]:
    return (
        db.query(User)
        .filter(
            (User.email == email_or_mobile) | (User.mobile == email_or_mobile)
        )
        .first()
    )


def get_user_by_id(db: Session, user_id: str) -> Optional[User]:
    return db.query(User).filter(User.id == user_id).first()


def create_user(db: Session, name: str, email: str, password: str, mobile: Optional[str] = None) -> User:
    user = User(
        name=name,
        email=email,
        mobile=mobile,
        hashed_password=hash_password(password),
    )
    db.add(user)
    db.flush()
    # Create empty subscription record
    sub = Subscription(user_id=user.id, is_active=False)
    db.add(sub)
    db.commit()
    db.refresh(user)
    return user


def is_premium(db: Session, user_id: str) -> bool:
    sub = db.query(Subscription).filter(
        Subscription.user_id == user_id,
        Subscription.is_active == True,
        Subscription.expires_at > datetime.now(timezone.utc),
    ).first()
    return sub is not None


def build_user_response(user: User, db: Session, token: str) -> dict:
    premium = is_premium(db, user.id)
    sub = db.query(Subscription).filter(Subscription.user_id == user.id).first()
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "mobile": user.mobile,
        "avatar_url": user.avatar_url,
        "is_premium": premium,
        "premium_expiry": sub.expires_at if sub and premium else None,
        "token": token,
    }

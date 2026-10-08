from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
from ..database.connection import get_db
from ..schemas.schemas import LoginRequest, RegisterRequest, ForgotPasswordRequest, UserResponse
from ..services.auth_service import (
    get_user_by_email_or_mobile, verify_password, create_access_token,
    create_user, build_user_response, get_user_by_id
)
from ..api.dependencies import get_current_user
from ..models.db_models import User

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=UserResponse)
def login(body: LoginRequest, db: Session = Depends(get_db)):
    user = get_user_by_email_or_mobile(db, body.email_or_mobile)
    if not user or not verify_password(body.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is disabled")
    token = create_access_token(user.id)
    return build_user_response(user, db, token)


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(body: RegisterRequest, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == body.email).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")
    if body.mobile:
        existing_mobile = db.query(User).filter(User.mobile == body.mobile).first()
        if existing_mobile:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Mobile already registered")
    user = create_user(db, body.name, body.email, body.password, body.mobile)
    token = create_access_token(user.id)
    return build_user_response(user, db, token)


@router.post("/forgot-password", status_code=status.HTTP_200_OK)
def forgot_password(body: ForgotPasswordRequest, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    # Always return 200 to prevent email enumeration
    user = db.query(User).filter(User.email == body.email).first()
    if user:
        # TODO: Generate reset token and send email via background task
        pass
    return {"message": "If the email exists, a reset link has been sent"}


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    token = ""  # Token already validated, return empty (client has it)
    return build_user_response(current_user, db, token)

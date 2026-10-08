import firebase_admin
from firebase_admin import credentials, messaging
from sqlalchemy.orm import Session
from ..models.db_models import User, Notification
from ..utils.config import get_settings
import os

settings = get_settings()
_firebase_initialized = False


def _init_firebase():
    global _firebase_initialized
    if not _firebase_initialized and os.path.exists(settings.firebase_credentials_path):
        cred = credentials.Certificate(settings.firebase_credentials_path)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True


def send_push_notification(fcm_token: str, title: str, body: str, data: dict = None) -> bool:
    _init_firebase()
    if not _firebase_initialized:
        return False
    try:
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data=data or {},
            token=fcm_token,
            android=messaging.AndroidConfig(priority="high"),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(sound="default", badge=1)
                )
            ),
        )
        messaging.send(message)
        return True
    except Exception:
        return False


def notify_users_about_match_event(
    db: Session,
    match_id: str,
    event_type: str,
    title: str,
    body: str,
):
    """Send notifications to users who have favorited teams in this match."""
    # Get users who favorited either team in this match
    from ..models.db_models import Match, Favorite
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        return

    team_ids = [match.team1_id, match.team2_id]
    favorites = db.query(Favorite).filter(
        Favorite.item_type == "team",
        Favorite.item_id.in_(team_ids),
    ).all()

    user_ids = list({f.user_id for f in favorites})
    users = db.query(User).filter(User.id.in_(user_ids), User.fcm_token.isnot(None)).all()

    for user in users:
        # Save notification to DB
        notif = Notification(
            user_id=user.id,
            title=title,
            body=body,
            type=event_type,
        )
        db.add(notif)
        # Send push
        if user.fcm_token:
            send_push_notification(user.fcm_token, title, body, {"match_id": match_id, "type": event_type})

    db.commit()

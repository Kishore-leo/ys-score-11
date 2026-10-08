import httpx
import json
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy.orm import Session
from ..models.db_models import Subscription, Payment
from ..utils.config import get_settings

settings = get_settings()


async def verify_google_play_purchase(purchase_token: str, product_id: str) -> dict:
    """
    Verify a Google Play subscription purchase using the Google Play Developer API.
    Requires a service account with proper permissions.
    """
    # Use google-auth to get an access token for the service account
    try:
        from google.oauth2 import service_account
        import google.auth.transport.requests

        credentials = service_account.Credentials.from_service_account_file(
            "google-service-account.json",
            scopes=["https://www.googleapis.com/auth/androidpublisher"],
        )
        request = google.auth.transport.requests.Request()
        credentials.refresh(request)
        access_token = credentials.token

        url = (
            f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/"
            f"{settings.google_play_package_name}/purchases/subscriptions/"
            f"{product_id}/tokens/{purchase_token}"
        )
        async with httpx.AsyncClient() as client:
            resp = await client.get(url, headers={"Authorization": f"Bearer {access_token}"})
            resp.raise_for_status()
            data = resp.json()

        expiry_ms = int(data.get("expiryTimeMillis", 0))
        expiry = datetime.fromtimestamp(expiry_ms / 1000, tz=timezone.utc)
        is_active = data.get("paymentState") == 1 and expiry > datetime.now(timezone.utc)

        return {"success": is_active, "expires_at": expiry, "platform": "android"}
    except Exception as e:
        raise ValueError(f"Google Play verification failed: {str(e)}")


async def verify_apple_purchase(receipt_data: str) -> dict:
    """
    Verify an Apple App Store subscription receipt.
    """
    payload = {
        "receipt-data": receipt_data,
        "password": settings.apple_shared_secret,
        "exclude-old-transactions": True,
    }
    # Try production first, then sandbox
    for url in [
        "https://buy.itunes.apple.com/verifyReceipt",
        "https://sandbox.itunes.apple.com/verifyReceipt",
    ]:
        async with httpx.AsyncClient() as client:
            resp = await client.post(url, json=payload)
            data = resp.json()

        status = data.get("status", -1)
        if status == 21007:
            continue  # Sandbox receipt sent to production, retry with sandbox
        if status != 0:
            raise ValueError(f"Apple receipt verification failed with status {status}")

        latest = data.get("latest_receipt_info", [])
        if not latest:
            raise ValueError("No receipt info found")

        latest_receipt = sorted(latest, key=lambda x: int(x.get("expires_date_ms", 0)))[-1]
        expiry_ms = int(latest_receipt.get("expires_date_ms", 0))
        expiry = datetime.fromtimestamp(expiry_ms / 1000, tz=timezone.utc)
        is_active = expiry > datetime.now(timezone.utc)

        return {"success": is_active, "expires_at": expiry, "platform": "ios"}

    raise ValueError("Apple receipt verification failed")


def activate_subscription(
    db: Session,
    user_id: str,
    purchase_token: str,
    product_id: str,
    platform: str,
    expires_at: datetime,
    amount: float = 5.0,
) -> Subscription:
    sub = db.query(Subscription).filter(Subscription.user_id == user_id).first()
    if not sub:
        sub = Subscription(user_id=user_id)
        db.add(sub)

    sub.is_active = True
    sub.product_id = product_id
    sub.purchase_token = purchase_token
    sub.platform = platform
    sub.started_at = datetime.now(timezone.utc)
    sub.expires_at = expires_at

    payment = Payment(
        subscription_id=sub.id,
        amount=amount,
        currency="INR",
        status="success",
        purchase_token=purchase_token,
    )
    db.add(payment)
    db.commit()
    db.refresh(sub)
    return sub

from sqlalchemy import (
    Column, String, Boolean, DateTime, Float, Integer,
    ForeignKey, Text, JSON, Enum
)
from sqlalchemy.orm import relationship, DeclarativeBase
from sqlalchemy.sql import func
import uuid
import enum


def gen_uuid():
    return str(uuid.uuid4())


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=gen_uuid)
    name = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, nullable=False, index=True)
    mobile = Column(String(20), unique=True, nullable=True)
    hashed_password = Column(String(255), nullable=False)
    avatar_url = Column(String(500), nullable=True)
    is_active = Column(Boolean, default=True)
    fcm_token = Column(String(500), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    subscription = relationship("Subscription", back_populates="user", uselist=False)
    favorites = relationship("Favorite", back_populates="user")
    notifications = relationship("Notification", back_populates="user")


class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, unique=True)
    is_active = Column(Boolean, default=False)
    product_id = Column(String(100), nullable=True)
    purchase_token = Column(Text, nullable=True)
    platform = Column(String(20), nullable=True)  # android / ios
    started_at = Column(DateTime(timezone=True), nullable=True)
    expires_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User", back_populates="subscription")
    payments = relationship("Payment", back_populates="subscription")


class Payment(Base):
    __tablename__ = "payments"

    id = Column(String, primary_key=True, default=gen_uuid)
    subscription_id = Column(String, ForeignKey("subscriptions.id"), nullable=False)
    amount = Column(Float, nullable=False)
    currency = Column(String(10), default="INR")
    status = Column(String(20), nullable=False)  # success / failed / pending
    purchase_token = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    subscription = relationship("Subscription", back_populates="payments")


class Team(Base):
    __tablename__ = "teams"

    id = Column(String, primary_key=True, default=gen_uuid)
    name = Column(String(100), nullable=False)
    short_name = Column(String(10), nullable=False)
    logo_url = Column(String(500), nullable=True)
    country = Column(String(100), nullable=True)
    external_id = Column(String(100), nullable=True, unique=True)  # from cricket API


class Player(Base):
    __tablename__ = "players"

    id = Column(String, primary_key=True, default=gen_uuid)
    name = Column(String(100), nullable=False)
    team_id = Column(String, ForeignKey("teams.id"), nullable=True)
    photo_url = Column(String(500), nullable=True)
    role = Column(String(50), nullable=True)
    nationality = Column(String(100), nullable=True)
    external_id = Column(String(100), nullable=True, unique=True)
    stats = Column(JSON, nullable=True)

    team = relationship("Team")


class Match(Base):
    __tablename__ = "matches"

    id = Column(String, primary_key=True, default=gen_uuid)
    external_id = Column(String(100), nullable=True, unique=True)
    match_type = Column(String(20), nullable=False)  # T20, ODI, Test
    status = Column(String(20), nullable=False)  # live, upcoming, completed
    team1_id = Column(String, ForeignKey("teams.id"), nullable=False)
    team2_id = Column(String, ForeignKey("teams.id"), nullable=False)
    venue = Column(String(200), nullable=True)
    match_date = Column(DateTime(timezone=True), nullable=False)
    result = Column(String(300), nullable=True)
    toss_winner = Column(String(100), nullable=True)
    toss_decision = Column(String(20), nullable=True)
    series_id = Column(String, ForeignKey("series.id"), nullable=True)
    match_data = Column(JSON, nullable=True)  # full live data from API
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    team1 = relationship("Team", foreign_keys=[team1_id])
    team2 = relationship("Team", foreign_keys=[team2_id])
    series = relationship("Series", back_populates="matches")
    scorecard = relationship("Scorecard", back_populates="match", uselist=False)
    ball_by_ball = relationship("BallByBall", back_populates="match")
    predictions = relationship("Prediction", back_populates="match")


class Scorecard(Base):
    __tablename__ = "scorecards"

    id = Column(String, primary_key=True, default=gen_uuid)
    match_id = Column(String, ForeignKey("matches.id"), nullable=False, unique=True)
    innings1_data = Column(JSON, nullable=True)
    innings2_data = Column(JSON, nullable=True)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    match = relationship("Match", back_populates="scorecard")


class BallByBall(Base):
    __tablename__ = "ball_by_ball"

    id = Column(String, primary_key=True, default=gen_uuid)
    match_id = Column(String, ForeignKey("matches.id"), nullable=False)
    innings = Column(Integer, nullable=False)
    over_number = Column(Integer, nullable=False)
    ball_number = Column(Integer, nullable=False)
    event = Column(String(10), nullable=False)
    commentary = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    match = relationship("Match", back_populates="ball_by_ball")


class Series(Base):
    __tablename__ = "series"

    id = Column(String, primary_key=True, default=gen_uuid)
    external_id = Column(String(100), nullable=True, unique=True)
    name = Column(String(200), nullable=False)
    type = Column(String(50), nullable=True)
    status = Column(String(20), nullable=False)
    start_date = Column(DateTime(timezone=True), nullable=True)
    end_date = Column(DateTime(timezone=True), nullable=True)
    logo_url = Column(String(500), nullable=True)

    matches = relationship("Match", back_populates="series")


class Favorite(Base):
    __tablename__ = "favorites"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    item_type = Column(String(20), nullable=False)  # team, player, series
    item_id = Column(String(100), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="favorites")


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    title = Column(String(200), nullable=False)
    body = Column(Text, nullable=False)
    type = Column(String(50), nullable=True)  # wicket, fifty, hundred, result, etc.
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="notifications")


class Prediction(Base):
    __tablename__ = "predictions"

    id = Column(String, primary_key=True, default=gen_uuid)
    match_id = Column(String, ForeignKey("matches.id"), nullable=False)
    team1_win_probability = Column(Float, nullable=False)
    team2_win_probability = Column(Float, nullable=False)
    predicted_winner = Column(String(100), nullable=False)
    confidence = Column(Float, nullable=False)
    explanation = Column(Text, nullable=True)
    factors = Column(JSON, nullable=True)
    model_version = Column(String(20), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    match = relationship("Match", back_populates="predictions")

"""
YS SCORE 11 — AI Match Prediction Module

Uses a Random Forest classifier trained on historical cricket match data.
Features: team form, batting/bowling strength, venue history, toss, current score.
"""

import os
import numpy as np
import joblib
from typing import Optional
from sqlalchemy.orm import Session

MODEL_PATH = os.path.join(os.path.dirname(__file__), "trained_model.pkl")
_model = None


def _load_model():
    global _model
    if _model is None and os.path.exists(MODEL_PATH):
        _model = joblib.load(MODEL_PATH)
    return _model


def _extract_features(match_data: dict) -> np.ndarray:
    """
    Extract feature vector from match data for prediction.
    Feature order must match training data exactly.
    """
    t1 = match_data.get("team1", {})
    t2 = match_data.get("team2", {})

    features = [
        # Team form (win rate last 5 matches)
        match_data.get("team1_form", 0.5),
        match_data.get("team2_form", 0.5),
        # Batting strength (avg runs per match)
        match_data.get("team1_batting_avg", 150.0) / 300.0,
        match_data.get("team2_batting_avg", 150.0) / 300.0,
        # Bowling strength (avg wickets per match)
        match_data.get("team1_bowling_avg", 5.0) / 10.0,
        match_data.get("team2_bowling_avg", 5.0) / 10.0,
        # Venue win rate for team1
        match_data.get("team1_venue_win_rate", 0.5),
        # Toss advantage (1 if team1 won toss, 0 otherwise)
        1.0 if match_data.get("toss_winner") == "team1" else 0.0,
        # Head-to-head win rate for team1
        match_data.get("h2h_win_rate", 0.5),
        # Current match state (if live)
        match_data.get("current_run_rate", 0.0) / 15.0,
        match_data.get("required_run_rate", 0.0) / 15.0,
        (t1.get("wickets") or 0) / 10.0,
        (t1.get("overs") or 0) / 50.0,
    ]
    return np.array(features, dtype=np.float32).reshape(1, -1)


def predict_winner(match_data: dict) -> dict:
    """
    Predict match winner using the trained ML model.
    Falls back to heuristic if model is not available.
    """
    model = _load_model()

    if model is not None:
        features = _extract_features(match_data)
        proba = model.predict_proba(features)[0]
        team1_prob = float(proba[1])
        team2_prob = float(proba[0])
        confidence = max(team1_prob, team2_prob) * 100
    else:
        # Heuristic fallback when model not trained yet
        team1_form = match_data.get("team1_form", 0.5)
        team2_form = match_data.get("team2_form", 0.5)
        venue_bonus = match_data.get("team1_venue_win_rate", 0.5) * 0.1
        toss_bonus = 0.05 if match_data.get("toss_winner") == "team1" else 0.0
        raw = team1_form + venue_bonus + toss_bonus
        team1_prob = min(max(raw / (raw + team2_form), 0.1), 0.9)
        team2_prob = 1.0 - team1_prob
        confidence = max(team1_prob, team2_prob) * 100

    predicted_winner = match_data.get("team1_name") if team1_prob >= team2_prob else match_data.get("team2_name")

    explanation = _build_explanation(match_data, team1_prob, team2_prob)

    return {
        "match_id": match_data.get("match_id", ""),
        "team1_id": match_data.get("team1_id", ""),
        "team1_name": match_data.get("team1_name", "Team 1"),
        "team2_id": match_data.get("team2_id", ""),
        "team2_name": match_data.get("team2_name", "Team 2"),
        "team1_win_probability": round(team1_prob, 4),
        "team2_win_probability": round(team2_prob, 4),
        "predicted_winner": predicted_winner,
        "confidence": round(confidence, 2),
        "explanation": explanation,
        "factors": {
            "team_form": {
                match_data.get("team1_name", "T1"): match_data.get("team1_form", 0.5),
                match_data.get("team2_name", "T2"): match_data.get("team2_form", 0.5),
            },
            "home_advantage": match_data.get("team1_venue_win_rate", 0.5) - 0.5,
            "batting_strength": {
                match_data.get("team1_name", "T1"): match_data.get("team1_batting_avg", 150) / 300,
                match_data.get("team2_name", "T2"): match_data.get("team2_batting_avg", 150) / 300,
            },
            "bowling_strength": {
                match_data.get("team1_name", "T1"): match_data.get("team1_bowling_avg", 5) / 10,
                match_data.get("team2_name", "T2"): match_data.get("team2_bowling_avg", 5) / 10,
            },
            "venue_history": {
                match_data.get("team1_name", "T1"): match_data.get("team1_venue_win_rate", 0.5),
            },
        },
    }


def _build_explanation(match_data: dict, t1_prob: float, t2_prob: float) -> str:
    t1 = match_data.get("team1_name", "Team 1")
    t2 = match_data.get("team2_name", "Team 2")
    winner = t1 if t1_prob >= t2_prob else t2
    loser = t2 if t1_prob >= t2_prob else t1
    margin = abs(t1_prob - t2_prob)

    if margin > 0.3:
        strength = "strong"
    elif margin > 0.15:
        strength = "moderate"
    else:
        strength = "slight"

    parts = [f"{winner} has a {strength} advantage over {loser}."]

    if match_data.get("team1_form", 0.5) > 0.6:
        parts.append(f"{t1} is in excellent recent form.")
    if match_data.get("team1_venue_win_rate", 0.5) > 0.6:
        parts.append(f"{t1} has a strong record at this venue.")
    if match_data.get("toss_winner") == "team1":
        parts.append(f"{t1} won the toss, which provides a tactical advantage.")

    crr = match_data.get("current_run_rate", 0)
    rrr = match_data.get("required_run_rate", 0)
    if crr > 0 and rrr > 0:
        if crr >= rrr:
            parts.append(f"Current run rate ({crr:.2f}) is ahead of required ({rrr:.2f}).")
        else:
            parts.append(f"Required run rate ({rrr:.2f}) is challenging vs current ({crr:.2f}).")

    return " ".join(parts)


async def get_prediction_for_match(match_id: str, db: Session) -> Optional[dict]:
    """Fetch match data from DB and generate prediction."""
    from ..models.db_models import Match, Team

    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        return None

    match_data_raw = match.match_data or {}
    match_input = {
        "match_id": match_id,
        "team1_id": match.team1_id,
        "team1_name": match.team1.name if match.team1 else "Team 1",
        "team2_id": match.team2_id,
        "team2_name": match.team2.name if match.team2 else "Team 2",
        "toss_winner": "team1" if match.toss_winner == match.team1_id else "team2",
        # These would come from historical stats in production
        "team1_form": match_data_raw.get("team1_form", 0.5),
        "team2_form": match_data_raw.get("team2_form", 0.5),
        "team1_batting_avg": match_data_raw.get("team1_batting_avg", 150.0),
        "team2_batting_avg": match_data_raw.get("team2_batting_avg", 150.0),
        "team1_bowling_avg": match_data_raw.get("team1_bowling_avg", 5.0),
        "team2_bowling_avg": match_data_raw.get("team2_bowling_avg", 5.0),
        "team1_venue_win_rate": match_data_raw.get("team1_venue_win_rate", 0.5),
        "h2h_win_rate": match_data_raw.get("h2h_win_rate", 0.5),
        "current_run_rate": match_data_raw.get("current_run_rate", 0.0),
        "required_run_rate": match_data_raw.get("required_run_rate", 0.0),
    }

    return predict_winner(match_input)

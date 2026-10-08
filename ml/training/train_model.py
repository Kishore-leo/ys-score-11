"""
YS SCORE 11 — ML Model Training Script

Run this script to train the cricket match prediction model.
Usage: python -m ml.training.train_model

Dataset: Place your historical match CSV in ml/dataset/matches.csv
Expected columns:
  team1_form, team2_form, team1_batting_avg, team2_batting_avg,
  team1_bowling_avg, team2_bowling_avg, team1_venue_win_rate,
  toss_won_by_team1, h2h_win_rate, current_run_rate, required_run_rate,
  team1_wickets, team1_overs, team1_won (target: 1=team1 won, 0=team2 won)
"""

import os
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.metrics import classification_report, accuracy_score
import joblib

DATASET_PATH = os.path.join(os.path.dirname(__file__), "..", "dataset", "matches.csv")
MODEL_OUTPUT = os.path.join(os.path.dirname(__file__), "..", "trained_model.pkl")

FEATURE_COLS = [
    "team1_form", "team2_form",
    "team1_batting_avg_norm", "team2_batting_avg_norm",
    "team1_bowling_avg_norm", "team2_bowling_avg_norm",
    "team1_venue_win_rate", "toss_won_by_team1",
    "h2h_win_rate", "current_run_rate_norm",
    "required_run_rate_norm", "team1_wickets_norm", "team1_overs_norm",
]
TARGET_COL = "team1_won"


def load_and_preprocess(path: str) -> tuple:
    df = pd.read_csv(path)

    # Normalize continuous features
    df["team1_batting_avg_norm"] = df["team1_batting_avg"] / 300.0
    df["team2_batting_avg_norm"] = df["team2_batting_avg"] / 300.0
    df["team1_bowling_avg_norm"] = df["team1_bowling_avg"] / 10.0
    df["team2_bowling_avg_norm"] = df["team2_bowling_avg"] / 10.0
    df["current_run_rate_norm"] = df.get("current_run_rate", pd.Series(0, index=df.index)) / 15.0
    df["required_run_rate_norm"] = df.get("required_run_rate", pd.Series(0, index=df.index)) / 15.0
    df["team1_wickets_norm"] = df.get("team1_wickets", pd.Series(0, index=df.index)) / 10.0
    df["team1_overs_norm"] = df.get("team1_overs", pd.Series(0, index=df.index)) / 50.0

    # Fill missing
    df = df.fillna(0.5)

    X = df[FEATURE_COLS].values
    y = df[TARGET_COL].values
    return X, y


def train():
    if not os.path.exists(DATASET_PATH):
        print(f"Dataset not found at {DATASET_PATH}")
        print("Generating synthetic training data for demonstration...")
        X, y = _generate_synthetic_data()
    else:
        print(f"Loading dataset from {DATASET_PATH}")
        X, y = load_and_preprocess(DATASET_PATH)

    print(f"Dataset size: {len(X)} samples, {X.shape[1]} features")

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Ensemble: Random Forest + Gradient Boosting
    pipeline = Pipeline([
        ("scaler", StandardScaler()),
        ("model", RandomForestClassifier(
            n_estimators=200,
            max_depth=8,
            min_samples_split=5,
            random_state=42,
            n_jobs=-1,
        )),
    ])

    pipeline.fit(X_train, y_train)

    # Evaluate
    y_pred = pipeline.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    cv_scores = cross_val_score(pipeline, X, y, cv=5, scoring="accuracy")

    print(f"\nTest Accuracy: {acc:.4f}")
    print(f"Cross-Val Accuracy: {cv_scores.mean():.4f} ± {cv_scores.std():.4f}")
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred, target_names=["Team 2 wins", "Team 1 wins"]))

    # Save model
    joblib.dump(pipeline, MODEL_OUTPUT)
    print(f"\nModel saved to {MODEL_OUTPUT}")


def _generate_synthetic_data(n_samples: int = 5000) -> tuple:
    """Generate synthetic training data for demonstration."""
    np.random.seed(42)
    X = np.random.rand(n_samples, len(FEATURE_COLS))

    # Simulate realistic win probability based on features
    # team1_form (idx 0) and team1_batting_avg (idx 2) are most important
    score = (
        X[:, 0] * 0.25 +   # team1_form
        X[:, 2] * 0.20 +   # team1_batting_avg
        X[:, 4] * 0.15 +   # team1_bowling_avg
        X[:, 6] * 0.10 +   # venue_win_rate
        X[:, 7] * 0.05 +   # toss
        X[:, 8] * 0.10 +   # h2h
        (1 - X[:, 1]) * 0.15  # team2_form (inverse)
    )
    y = (score > 0.5).astype(int)
    return X, y


if __name__ == "__main__":
    train()

# YS SCORE 11 — Professional Cricket Match Scoring Mobile Application
### By Young Storms

**YS SCORE 11** is a ground-ready cricket match scoring mobile application built with **Flutter & Dart**. It empowers scorers, teams, and tournament organizers to create real matches, select playing squads, conduct coin tosses, and manually score ball-by-ball deliveries on the cricket field with single-handed ease, professional dark theme aesthetics, zero-loss multi-level undo, detailed scorecards, player career statistics, tournament points tables (with Net Run Rate), and an in-play AI match win prediction engine designed for an **AIML final-year project**.

---

## 🚀 Key Features

### 1. Brand Identity & App Opening Flow
- **Dark Premium Cricket Theme**: Deep slate `#0A0E17`, vibrant cricket turf green `#00E676`, cyan highlights `#00E5FF`, and golden accents `#FFB300`.
- **Screen 1**: Professional animated entrance displaying **YS SCORE 11**.
- **Screen 2**: Official **Young Storms** brand logo reveal with glow ring.
- **Screen 3**: Authentication (Login, Register, Forgot Password) with local persistent session management.

### 2. Home Dashboard
- **Prominent "+ CREATE MATCH" Hero Button**: Large, high-visibility CTA for starting matches.
- **Live / Running Matches**: Instant access to ongoing matches with live scores, current over, run rate, and a one-tap **"RESUME SCORING"** button.
- **Recent Matches**: Completed matches list with winner margins, top performers, and direct scorecard links.
- **Cricket Hub Navigation**: Quick cards for Teams, Players, Stats, Tournaments, AI Predictor, and Premium membership.

### 3. Multi-Step Match Creation Flow (5 Steps)
1. **Step 1 - Match Details**: Match Title, Format (T10, T20, ODI / 50 Overs, Custom Overs), Number of Overs, Ground / Venue, Match Date, and Start Time.
2. **Step 2 - Team Selection**: Pick Team A and Team B from existing rosters or create a new team inline.
3. **Step 3 - Player Selection**: Select playing squad for both teams, filter roles (Batsman, Bowler, All-Rounder, Wicketkeeper), or add new players directly.
4. **Step 4 - Toss**: Interactive coin toss selection (Team A / Team B won toss → Elected to Bat First / Bowl First).
5. **Step 5 - Match Confirmation & Summary**: Complete pre-match verification before opening the pitch scoring pad.
6. **Opening Players Dialog**: Pick Striker, Non-Striker, and Opening Bowler before ball 1.

### 4. Ground-Optimized Scoring Engine
- **One-Handed Touch Controls**: Large, high-contrast, easy-to-tap scoring buttons (`0`, `1`, `2`, `3`, `4`, `6`).
- **Complete Cricket Rules Implemented**:
  - **Normal Balls**: 0–6 runs, legal ball counter, batsman runs/balls, bowler balls/runs, strike rotation on odd runs (1, 3, 5).
  - **Wide**: +1 extra team run, ball not counted as legal delivery, bowler charged run, does not add to batsman balls, physical running runs supported.
  - **No Ball**: +1 extra team run + bat runs tracked separately (e.g. No Ball + 4), ball not counted as legal delivery.
  - **Byes & Leg Byes**: Runs added to team extras, legal delivery, 0 runs to batsman, strike rotates on odd running runs.
  - **Wickets**: 7 dismissal types (Bowled, Caught, LBW, Run Out, Stumped, Hit Wicket, Retired). Bowler credit rule accurately enforced (Bowled/Caught/LBW/Stumped/Hit Wicket count towards bowler; Run Out and Retired do not). Fielder selector and incoming batsman picker.
  - **Over Management**: Exactly 6 legal deliveries per over, automatic strike swap, maiden over calculation, and bowler rotation.
  - **Full Snapshot Undo**: Every ball takes a deep immutable snapshot of the match state, allowing loss-free rollback of any ball, extra, wicket, or over change.
  - **Innings Break & Second Innings**: Automatic all-out and max overs detection, target setting, RRR calculation, and target chasing victory detection.

### 5. Full Scorecard & Match Result
- **Scorecard**: Tabbed 1st & 2nd innings scorecards with Batting (R, B, 4s, 6s, SR, dismissal detail), Bowling (O, M, R, W, Econ), Extras breakdown, and Fall of Wickets (FOW) timeline.
- **Match Result**: Winner declaration, winning margin (e.g., "Young Storms XI won by 24 runs" or "Thunderbolts CC won by 6 wickets"), Player of the Match calculation, top batsman, and best bowler.

### 6. AIML Final-Year Project Feature: AI Match Win Predictor
- Real-time in-play win probability model calculating Team A % vs Team B %.
- Key feature weights: wickets in hand, current run rate vs required run rate pressure, overs remaining, target difficulty, and toss advantage.
- Natural language explanation summarizing why the odds shifted.
- Clean architecture prepared to connect to a Python + FastAPI + Scikit-Learn backend at `/api/ml/predict`.

### 7. Teams, Players & Tournaments
- **Teams**: Create, edit, and manage teams, logos, captains, and vice-captains.
- **Players**: Career statistics auto-calculated across matches (Matches, Innings, Runs, Average, Strike Rate, 4s, 6s, 50s, 100s, HS, Wickets, Economy, Best Bowling).
- **Tournaments**: Points table with auto-calculated Net Run Rate (NRR):
  $$\text{NRR} = \left(\frac{\text{Runs Scored}}{\text{Overs Faced}}\right) - \left(\frac{\text{Runs Conceded}}{\text{Overs Bowled}}\right)$$

### 8. Premium Membership (₹5 / month)
- Pro membership interface ready for Google Play Billing and cloud sync.

---

## 📁 Project Architecture

```
ys score 11/
├── lib/
│   ├── main.dart                          # Application entry point, multi-provider setup
│   ├── theme/
│   │   └── app_theme.dart                 # YS SCORE 11 dark theme & cricket colors
│   ├── models/
│   │   ├── player.dart                    # Player, roles, career stats
│   │   ├── team.dart                      # Team model with captain/vice-captain
│   │   ├── ball_record.dart               # Ball delivery, extras, wicket types
│   │   ├── over_record.dart               # Over record, maiden calculation
│   │   ├── innings_data.dart              # Innings, scorecards, fall of wickets
│   │   ├── cricket_match.dart             # Match metadata, status, target logic
│   │   ├── tournament.dart                # Tournament & Points Table with NRR
│   │   └── user_model.dart                # User profile & subscription status
│   ├── services/
│   │   ├── storage_service.dart           # Persistent SharedPreferences storage
│   │   ├── mock_data_service.dart         # Starter teams & demo completed match
│   │   └── ai_predictor_service.dart      # AIML in-play win probability model
│   ├── providers/
│   │   ├── auth_provider.dart             # User session & pro upgrade
│   │   ├── teams_provider.dart            # Team & player CRUD + career stats
│   │   ├── tournament_provider.dart       # Tournaments & points table calculations
│   │   └── scoring_provider.dart          # Core cricket scoring engine & undo stack
│   └── screens/
│       ├── splash/
│       │   ├── splash_screen.dart         # Animated "YS SCORE 11" screen
│       │   └── logo_splash_screen.dart    # Young Storms brand logo reveal
│       ├── auth/
│       │   ├── login_screen.dart          # Login with demo autofill
│       │   ├── register_screen.dart       # New account registration
│       │   └── forgot_password_screen.dart# Password reset
│       ├── home/
│       │   └── home_screen.dart           # Dashboard, prominent +CREATE MATCH, live cards
│       ├── match_creation/
│       │   └── create_match_wizard.dart   # 5-step match creation flow
│       ├── scoring/
│       │   ├── opening_players_dialog.dart# Select opening batsmen & bowler
│       │   ├── scoring_screen.dart        # Real-time ground scoring screen
│       │   ├── scorecard_screen.dart      # Tabbed full match scorecard
│       │   └── match_result_screen.dart   # Result, Player of the Match, summary
│       ├── teams/
│       │   └── teams_screen.dart          # Teams list & squad management
│       ├── players/
│       │   ├── players_screen.dart        # Searchable player directory
│       │   └── player_profile_screen.dart # Career batting & bowling statistics
│       ├── tournament/
│       │   └── tournament_screen.dart     # Tournaments & NRR points table
│       ├── ai_prediction/
│       │   └── ai_prediction_screen.dart  # AIML win probability gauge & factors
│       ├── statistics/
│       │   └── statistics_screen.dart     # Top run scorers & wicket takers
│       ├── premium/
│       │   └── premium_screen.dart        # ₹5/mo subscription view
│       └── profile/
│           └── profile_screen.dart        # User profile & settings
├── assets/
│   └── images/
│       └── young_storms_logo.png          # Official Young Storms logo
├── test/
│   ├── scoring_engine_test.dart           # Comprehensive scoring & undo unit tests
│   └── widget_test.dart                   # Splash screen widget test
├── backend/                               # Optional FastAPI Python backend
└── ml/                                    # Optional ML dataset & training scripts
```

---

## 🛠️ Getting Started & Verification

### 1. Run Flutter App
```powershell
# Get dependencies
flutter pub get

# Run unit tests
flutter test

# Run app on connected device (Windows Desktop, Chrome Web, or Android Emulator)
flutter run -d chrome
# or
flutter run -d windows
```

### 2. Verify Scoring Engine Tests
All 6 automated unit & widget tests pass:
```powershell
flutter test test/scoring_engine_test.dart
```
Tests cover:
- Match setup, toss, and opening players
- Normal deliveries and strike rotation
- Wides, No Balls, Byes, and Leg Byes
- Wicket dismissals and bowler credit rules
- Multi-level snapshot undo and state restoration

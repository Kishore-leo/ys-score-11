import 'dart:math' as math;
import '../models/cricket_match.dart';

class PredictionResult {
  final double teamAProbability; // 0.0 to 100.0
  final double teamBProbability; // 0.0 to 100.0
  final String favoredTeamName;
  final String explanation;
  final List<String> keyFactors;
  final bool isFromBackend;

  PredictionResult({
    required this.teamAProbability,
    required this.teamBProbability,
    required this.favoredTeamName,
    required this.explanation,
    required this.keyFactors,
    this.isFromBackend = false,
  });
}

class AiPredictorService {
  /// Computes real-time win probability for an active or configured match.
  /// Designed as the client-side predictor for an AIML final-year project with
  /// architecture ready for a Python + Scikit-learn backend.
  static PredictionResult predictWinProbability(CricketMatch match) {
    // 1. Before or at Toss stage (Pre-match prediction based on team composition & toss)
    if (match.status == MatchStatus.setup || match.status == MatchStatus.toss) {
      return _predictPreMatch(match);
    }

    // 2. 1st Innings in progress
    if (match.status == MatchStatus.inning1 || match.status == MatchStatus.inningBreak) {
      return _predictFirstInnings(match);
    }

    // 3. 2nd Innings in progress (Target chasing phase)
    if (match.status == MatchStatus.inning2) {
      return _predictSecondInnings(match);
    }

    // 4. Completed match
    if (match.status == MatchStatus.completed) {
      final isTeamAWinner = match.winnerTeamId == match.teamA.id;
      return PredictionResult(
        teamAProbability: isTeamAWinner ? 100.0 : 0.0,
        teamBProbability: isTeamAWinner ? 0.0 : 100.0,
        favoredTeamName: isTeamAWinner ? match.teamA.name : match.teamB.name,
        explanation: match.resultSummary ?? 'Match completed.',
        keyFactors: ['Final result locked in match history'],
      );
    }

    return _predictPreMatch(match);
  }

  static PredictionResult _predictPreMatch(CricketMatch match) {
    // Base 50-50 split, adjusted by toss if available
    double teamAScore = 50.0;
    final factors = <String>[];

    if (match.tossWinnerId != null) {
      final tossWinnerIsA = match.tossWinnerId == match.teamA.id;
      final advantage = match.tossDecision == TossDecision.bat ? 3.0 : 2.5;
      if (tossWinnerIsA) {
        teamAScore += advantage;
        factors.add('${match.teamA.name} won the toss and elected to ${match.tossDecision?.name}. (+$advantage%)');
      } else {
        teamAScore -= advantage;
        factors.add('${match.teamB.name} won the toss and elected to ${match.tossDecision?.name}. (+$advantage%)');
      }
    } else {
      factors.add('Even team baseline prior to toss');
    }

    factors.add('Format: ${match.matchTypeDisplayName} at ${match.venue.isNotEmpty ? match.venue : "neutral venue"}');
    final teamBScore = 100.0 - teamAScore;
    final favored = teamAScore >= 50.0 ? match.teamA.name : match.teamB.name;

    return PredictionResult(
      teamAProbability: teamAScore,
      teamBProbability: teamBScore,
      favoredTeamName: favored,
      explanation: 'Pre-match conditions suggest a balanced contest, weighted slightly by ground conditions and toss advantage.',
      keyFactors: factors,
    );
  }

  static PredictionResult _predictFirstInnings(CricketMatch match) {
    final inn1 = match.innings1;
    if (inn1 == null) return _predictPreMatch(match);

    final battingIsTeamA = inn1.battingTeamId == match.teamA.id;
    final totalBalls = match.totalOvers * 6;
    final ballsBowled = inn1.legalBallsBowled;
    final runs = inn1.totalRuns;
    final wickets = inn1.wickets;
    final crr = inn1.currentRunRate;

    // Projected total based on current run rate & wickets in hand
    final ballsRemaining = totalBalls - ballsBowled;
    final wicketsInHand = 10 - wickets;
    
    // Diminishing returns formula for projected score
    final wicketMultiplier = math.max(0.4, wicketsInHand / 10.0);
    final projectedAdditionalRuns = (ballsRemaining / 6.0) * (crr > 0 ? crr : 7.0) * wicketMultiplier;
    final projectedTotal = runs + projectedAdditionalRuns.round();

    // In modern T20: par score ~ 165, in T10 ~ 95, in ODI ~ 275
    final parScore = match.matchType == MatchType.t10
        ? 95
        : (match.matchType == MatchType.t20 ? 165 : 275);

    final scoreAdvantage = (projectedTotal - parScore) * 0.4;
    double battingWinProb = 50.0 + scoreAdvantage;
    battingWinProb = battingWinProb.clamp(15.0, 85.0);

    final teamAProb = battingIsTeamA ? battingWinProb : (100.0 - battingWinProb);
    final teamBProb = 100.0 - teamAProb;

    final favored = teamAProb >= 50.0 ? match.teamA.name : match.teamB.name;
    final factors = <String>[
      'Projected 1st Innings Total: ~$projectedTotal runs',
      'Current Run Rate: ${crr.toStringAsFixed(2)} RPO',
      'Wickets lost: $wickets (in ${inn1.oversString} overs)',
    ];

    return PredictionResult(
      teamAProbability: double.parse(teamAProb.toStringAsFixed(1)),
      teamBProbability: double.parse(teamBProb.toStringAsFixed(1)),
      favoredTeamName: favored,
      explanation: '${inn1.battingTeamName} is on pace for approximately $projectedTotal runs with $wicketsInHand wickets remaining. Match leverage depends on final overs acceleration.',
      keyFactors: factors,
    );
  }

  static PredictionResult _predictSecondInnings(CricketMatch match) {
    final inn2 = match.innings2;
    final target = match.targetRuns;
    if (inn2 == null || target == null) return _predictFirstInnings(match);

    final chasingIsTeamA = inn2.battingTeamId == match.teamA.id;
    final chasingRuns = inn2.totalRuns;
    final chasingWickets = inn2.wickets;
    final ballsLeft = match.remainingBalls ?? 0;
    final runsNeeded = match.requiredRuns ?? 0;
    final wicketsInHand = 10 - chasingWickets;

    // Victory check
    if (chasingRuns >= target) {
      return PredictionResult(
        teamAProbability: chasingIsTeamA ? 100.0 : 0.0,
        teamBProbability: chasingIsTeamA ? 0.0 : 100.0,
        favoredTeamName: chasingIsTeamA ? match.teamA.name : match.teamB.name,
        explanation: '${inn2.battingTeamName} has chased down the target successfully!',
        keyFactors: ['Target achieved'],
      );
    }

    if (chasingWickets >= 10 || ballsLeft <= 0) {
      return PredictionResult(
        teamAProbability: chasingIsTeamA ? 0.0 : 100.0,
        teamBProbability: chasingIsTeamA ? 100.0 : 0.0,
        favoredTeamName: chasingIsTeamA ? match.teamB.name : match.teamA.name,
        explanation: '${inn2.bowlingTeamName} defended the target successfully.',
        keyFactors: ['All wickets lost or overs finished'],
      );
    }

    final rrr = match.requiredRunRate ?? 6.0;
    final crr = inn2.currentRunRate;

    // Logistic regression model simulation:
    // log-odds z = beta_0 + beta_rrr * (RRR - CRR) + beta_wickets * (WicketsInHand) + beta_balls * (BallsLeft / TotalBalls)
    final rrrPressure = rrr - (crr > 0 ? crr : 7.0);
    double chasingProb = 50.0;

    // Heavy penalty for high RRR
    chasingProb -= rrrPressure * 6.5;

    // Heavy bonus/penalty for wickets in hand
    chasingProb += (wicketsInHand - 5) * 6.0;

    // Endgame adjustment when balls are few
    if (ballsLeft <= 18) {
      if (runsNeeded > ballsLeft * 2.5) {
        chasingProb -= 25.0; // Needs >15 RPO in death overs
      } else if (runsNeeded <= ballsLeft && wicketsInHand >= 4) {
        chasingProb += 25.0; // Less than run-a-ball with wickets
      }
    }

    chasingProb = chasingProb.clamp(2.0, 98.0);
    final teamAProb = chasingIsTeamA ? chasingProb : (100.0 - chasingProb);
    final teamBProb = 100.0 - teamAProb;
    final favored = teamAProb >= 50.0 ? match.teamA.name : match.teamB.name;

    final factors = <String>[
      'Equation: Need $runsNeeded runs from $ballsLeft balls',
      'Required Run Rate: ${rrr.toStringAsFixed(2)} RPO',
      'Wickets In Hand: $wicketsInHand wickets',
      'Current Run Rate: ${crr.toStringAsFixed(2)} RPO',
    ];

    String explanation;
    if (rrr <= 7.0 && wicketsInHand >= 6) {
      explanation = '${inn2.battingTeamName} is in firm control with plenty of wickets in hand and a manageable required run rate.';
    } else if (rrr >= 11.0 || wicketsInHand <= 3) {
      explanation = '${inn2.bowlingTeamName} holds the upper hand due to mounting required run rate pressure and depleted batting depth.';
    } else {
      explanation = 'A closely fought run chase! Boundaries in the next few overs will decisively swing the probability.';
    }

    return PredictionResult(
      teamAProbability: double.parse(teamAProb.toStringAsFixed(1)),
      teamBProbability: double.parse(teamBProb.toStringAsFixed(1)),
      favoredTeamName: favored,
      explanation: explanation,
      keyFactors: factors,
    );
  }
}

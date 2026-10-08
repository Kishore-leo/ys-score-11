import 'team.dart';
import 'innings_data.dart';

enum MatchType {
  t10,
  t20,
  odi,
  custom,
}

enum MatchStatus {
  setup,
  toss,
  inning1,
  inningBreak,
  inning2,
  completed,
}

enum TossDecision {
  bat,
  bowl,
}

class CricketMatch {
  final String id;
  String name;
  Team teamA;
  Team teamB;
  int totalOvers;
  MatchType matchType;
  String venue;
  DateTime matchDate;
  String startTime;
  MatchStatus status;

  String? tossWinnerId;
  TossDecision? tossDecision;
  String? battingFirstTeamId;

  InningsData? innings1;
  InningsData? innings2;

  int? targetRuns;
  String? winnerTeamId;
  String? winMargin;
  String? resultSummary;
  String? playerOfTheMatchId;

  final DateTime createdAt;
  DateTime updatedAt;

  CricketMatch({
    required this.id,
    required this.name,
    required this.teamA,
    required this.teamB,
    required this.totalOvers,
    this.matchType = MatchType.t20,
    this.venue = '',
    required this.matchDate,
    this.startTime = '10:00 AM',
    this.status = MatchStatus.setup,
    this.tossWinnerId,
    this.tossDecision,
    this.battingFirstTeamId,
    this.innings1,
    this.innings2,
    this.targetRuns,
    this.winnerTeamId,
    this.winMargin,
    this.resultSummary,
    this.playerOfTheMatchId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Team? get tossWinnerTeam => tossWinnerId == teamA.id
      ? teamA
      : (tossWinnerId == teamB.id ? teamB : null);

  Team? get battingFirstTeam => battingFirstTeamId == teamA.id
      ? teamA
      : (battingFirstTeamId == teamB.id ? teamB : null);

  Team? get bowlingFirstTeam => battingFirstTeamId == teamA.id
      ? teamB
      : (battingFirstTeamId == teamB.id ? teamA : null);

  InningsData? get currentInnings {
    if (status == MatchStatus.inning1) return innings1;
    if (status == MatchStatus.inning2) return innings2;
    if (status == MatchStatus.inningBreak) return innings1;
    if (status == MatchStatus.completed) return innings2 ?? innings1;
    return null;
  }

  bool get isSecondInnings => status == MatchStatus.inning2;

  int? get requiredRuns {
    if (targetRuns == null || innings2 == null) return null;
    final req = targetRuns! - innings2!.totalRuns;
    return req > 0 ? req : 0;
  }

  int? get remainingBalls {
    if (innings2 == null) return null;
    final totalBalls = totalOvers * 6;
    final ballsLeft = totalBalls - innings2!.legalBallsBowled;
    return ballsLeft > 0 ? ballsLeft : 0;
  }

  double? get requiredRunRate {
    final req = requiredRuns;
    final remBalls = remainingBalls;
    if (req == null || remBalls == null || remBalls <= 0) return null;
    final remOvers = remBalls / 6.0;
    return req / remOvers;
  }

  String get matchTypeDisplayName {
    switch (matchType) {
      case MatchType.t10:
        return 'T10';
      case MatchType.t20:
        return 'T20';
      case MatchType.odi:
        return 'ODI (50 Overs)';
      case MatchType.custom:
        return '$totalOvers Overs';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'teamA': teamA.toJson(),
        'teamB': teamB.toJson(),
        'totalOvers': totalOvers,
        'matchType': matchType.index,
        'venue': venue,
        'matchDate': matchDate.toIso8601String(),
        'startTime': startTime,
        'status': status.index,
        'tossWinnerId': tossWinnerId,
        'tossDecision': tossDecision?.index,
        'battingFirstTeamId': battingFirstTeamId,
        'innings1': innings1?.toJson(),
        'innings2': innings2?.toJson(),
        'targetRuns': targetRuns,
        'winnerTeamId': winnerTeamId,
        'winMargin': winMargin,
        'resultSummary': resultSummary,
        'playerOfTheMatchId': playerOfTheMatchId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CricketMatch.fromJson(Map<String, dynamic> json) => CricketMatch(
        id: json['id'] as String,
        name: json['name'] as String,
        teamA: Team.fromJson(json['teamA'] as Map<String, dynamic>),
        teamB: Team.fromJson(json['teamB'] as Map<String, dynamic>),
        totalOvers: json['totalOvers'] as int? ?? 20,
        matchType: MatchType.values[json['matchType'] as int? ?? 1],
        venue: json['venue'] as String? ?? '',
        matchDate: DateTime.parse(json['matchDate'] as String),
        startTime: json['startTime'] as String? ?? '10:00 AM',
        status: MatchStatus.values[json['status'] as int? ?? 0],
        tossWinnerId: json['tossWinnerId'] as String?,
        tossDecision: json['tossDecision'] != null
            ? TossDecision.values[json['tossDecision'] as int]
            : null,
        battingFirstTeamId: json['battingFirstTeamId'] as String?,
        innings1: json['innings1'] != null
            ? InningsData.fromJson(json['innings1'] as Map<String, dynamic>)
            : null,
        innings2: json['innings2'] != null
            ? InningsData.fromJson(json['innings2'] as Map<String, dynamic>)
            : null,
        targetRuns: json['targetRuns'] as int?,
        winnerTeamId: json['winnerTeamId'] as String?,
        winMargin: json['winMargin'] as String?,
        resultSummary: json['resultSummary'] as String?,
        playerOfTheMatchId: json['playerOfTheMatchId'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );

  CricketMatch deepCopy() {
    return CricketMatch(
      id: id,
      name: name,
      teamA: teamA.copyWith(),
      teamB: teamB.copyWith(),
      totalOvers: totalOvers,
      matchType: matchType,
      venue: venue,
      matchDate: matchDate,
      startTime: startTime,
      status: status,
      tossWinnerId: tossWinnerId,
      tossDecision: tossDecision,
      battingFirstTeamId: battingFirstTeamId,
      innings1: innings1?.deepCopy(),
      innings2: innings2?.deepCopy(),
      targetRuns: targetRuns,
      winnerTeamId: winnerTeamId,
      winMargin: winMargin,
      resultSummary: resultSummary,
      playerOfTheMatchId: playerOfTheMatchId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

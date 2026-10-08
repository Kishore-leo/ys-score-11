import 'ball_record.dart';
import 'over_record.dart';

class BatsmanScorecard {
  final String playerId;
  String playerName;
  int runs;
  int balls;
  int fours;
  int sixes;
  bool isOut;
  String dismissalText; // e.g. "b Bumrah", "c Kohli b Shami", "not out", "run out"
  WicketType? wicketType;
  String? bowlerId;
  String? fielderId;
  int battingOrder;

  BatsmanScorecard({
    required this.playerId,
    required this.playerName,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOut = false,
    this.dismissalText = 'not out',
    this.wicketType,
    this.bowlerId,
    this.fielderId,
    this.battingOrder = 1,
  });

  double get strikeRate => balls > 0 ? (runs / balls) * 100.0 : 0.0;

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'playerName': playerName,
        'runs': runs,
        'balls': balls,
        'fours': fours,
        'sixes': sixes,
        'isOut': isOut,
        'dismissalText': dismissalText,
        'wicketType': wicketType?.index,
        'bowlerId': bowlerId,
        'fielderId': fielderId,
        'battingOrder': battingOrder,
      };

  factory BatsmanScorecard.fromJson(Map<String, dynamic> json) => BatsmanScorecard(
        playerId: json['playerId'] as String,
        playerName: json['playerName'] as String,
        runs: json['runs'] as int? ?? 0,
        balls: json['balls'] as int? ?? 0,
        fours: json['fours'] as int? ?? 0,
        sixes: json['sixes'] as int? ?? 0,
        isOut: json['isOut'] as bool? ?? false,
        dismissalText: json['dismissalText'] as String? ?? 'not out',
        wicketType: json['wicketType'] != null
            ? WicketType.values[json['wicketType'] as int]
            : null,
        bowlerId: json['bowlerId'] as String?,
        fielderId: json['fielderId'] as String?,
        battingOrder: json['battingOrder'] as int? ?? 1,
      );

  BatsmanScorecard copy() => BatsmanScorecard(
        playerId: playerId,
        playerName: playerName,
        runs: runs,
        balls: balls,
        fours: fours,
        sixes: sixes,
        isOut: isOut,
        dismissalText: dismissalText,
        wicketType: wicketType,
        bowlerId: bowlerId,
        fielderId: fielderId,
        battingOrder: battingOrder,
      );
}

class BowlerScorecard {
  final String playerId;
  String playerName;
  int legalBallsBowled;
  int maidens;
  int runsConceded;
  int wickets;
  int noBalls;
  int wides;

  BowlerScorecard({
    required this.playerId,
    required this.playerName,
    this.legalBallsBowled = 0,
    this.maidens = 0,
    this.runsConceded = 0,
    this.wickets = 0,
    this.noBalls = 0,
    this.wides = 0,
  });

  String get oversString {
    final fullOvers = legalBallsBowled ~/ 6;
    final balls = legalBallsBowled % 6;
    return '$fullOvers.$balls';
  }

  double get economy {
    if (legalBallsBowled <= 0) return 0.0;
    final overs = legalBallsBowled / 6.0;
    return runsConceded / overs;
  }

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'playerName': playerName,
        'legalBallsBowled': legalBallsBowled,
        'maidens': maidens,
        'runsConceded': runsConceded,
        'wickets': wickets,
        'noBalls': noBalls,
        'wides': wides,
      };

  factory BowlerScorecard.fromJson(Map<String, dynamic> json) => BowlerScorecard(
        playerId: json['playerId'] as String,
        playerName: json['playerName'] as String,
        legalBallsBowled: json['legalBallsBowled'] as int? ?? 0,
        maidens: json['maidens'] as int? ?? 0,
        runsConceded: json['runsConceded'] as int? ?? 0,
        wickets: json['wickets'] as int? ?? 0,
        noBalls: json['noBalls'] as int? ?? 0,
        wides: json['wides'] as int? ?? 0,
      );

  BowlerScorecard copy() => BowlerScorecard(
        playerId: playerId,
        playerName: playerName,
        legalBallsBowled: legalBallsBowled,
        maidens: maidens,
        runsConceded: runsConceded,
        wickets: wickets,
        noBalls: noBalls,
        wides: wides,
      );
}

class FallOfWicket {
  final int wicketNumber;
  final int score;
  final String overs;
  final String batsmanId;
  final String batsmanName;

  FallOfWicket({
    required this.wicketNumber,
    required this.score,
    required this.overs,
    required this.batsmanId,
    required this.batsmanName,
  });

  Map<String, dynamic> toJson() => {
        'wicketNumber': wicketNumber,
        'score': score,
        'overs': overs,
        'batsmanId': batsmanId,
        'batsmanName': batsmanName,
      };

  factory FallOfWicket.fromJson(Map<String, dynamic> json) => FallOfWicket(
        wicketNumber: json['wicketNumber'] as int,
        score: json['score'] as int,
        overs: json['overs'] as String,
        batsmanId: json['batsmanId'] as String,
        batsmanName: json['batsmanName'] as String,
      );
}

class InningsData {
  final String battingTeamId;
  final String battingTeamName;
  final String bowlingTeamId;
  final String bowlingTeamName;

  int totalRuns;
  int wickets;
  int legalBallsBowled;

  String? currentStrikerId;
  String? currentNonStrikerId;
  String? currentBowlerId;

  int wides;
  int noBalls;
  int byes;
  int legByes;
  int penalty;

  Map<String, BatsmanScorecard> battingScorecards;
  Map<String, BowlerScorecard> bowlingScorecards;
  List<FallOfWicket> fallOfWickets;
  List<OverRecord> overs;
  List<BallRecord> ballHistory;
  bool isCompleted;

  InningsData({
    required this.battingTeamId,
    required this.battingTeamName,
    required this.bowlingTeamId,
    required this.bowlingTeamName,
    this.totalRuns = 0,
    this.wickets = 0,
    this.legalBallsBowled = 0,
    this.currentStrikerId,
    this.currentNonStrikerId,
    this.currentBowlerId,
    this.wides = 0,
    this.noBalls = 0,
    this.byes = 0,
    this.legByes = 0,
    this.penalty = 0,
    Map<String, BatsmanScorecard>? battingScorecards,
    Map<String, BowlerScorecard>? bowlingScorecards,
    List<FallOfWicket>? fallOfWickets,
    List<OverRecord>? overs,
    List<BallRecord>? ballHistory,
    this.isCompleted = false,
  })  : battingScorecards = battingScorecards ?? {},
        bowlingScorecards = bowlingScorecards ?? {},
        fallOfWickets = fallOfWickets ?? [],
        overs = overs ?? [],
        ballHistory = ballHistory ?? [];

  int get totalExtras => wides + noBalls + byes + legByes + penalty;

  String get oversString {
    final fullOvers = legalBallsBowled ~/ 6;
    final balls = legalBallsBowled % 6;
    return '$fullOvers.$balls';
  }

  double get currentRunRate {
    if (legalBallsBowled <= 0) return 0.0;
    return totalRuns / (legalBallsBowled / 6.0);
  }

  OverRecord? get currentOver => overs.isNotEmpty ? overs.last : null;

  Map<String, dynamic> toJson() => {
        'battingTeamId': battingTeamId,
        'battingTeamName': battingTeamName,
        'bowlingTeamId': bowlingTeamId,
        'bowlingTeamName': bowlingTeamName,
        'totalRuns': totalRuns,
        'wickets': wickets,
        'legalBallsBowled': legalBallsBowled,
        'currentStrikerId': currentStrikerId,
        'currentNonStrikerId': currentNonStrikerId,
        'currentBowlerId': currentBowlerId,
        'wides': wides,
        'noBalls': noBalls,
        'byes': byes,
        'legByes': legByes,
        'penalty': penalty,
        'battingScorecards': battingScorecards.map((k, v) => MapEntry(k, v.toJson())),
        'bowlingScorecards': bowlingScorecards.map((k, v) => MapEntry(k, v.toJson())),
        'fallOfWickets': fallOfWickets.map((f) => f.toJson()).toList(),
        'overs': overs.map((o) => o.toJson()).toList(),
        'ballHistory': ballHistory.map((b) => b.toJson()).toList(),
        'isCompleted': isCompleted,
      };

  factory InningsData.fromJson(Map<String, dynamic> json) => InningsData(
        battingTeamId: json['battingTeamId'] as String,
        battingTeamName: json['battingTeamName'] as String,
        bowlingTeamId: json['bowlingTeamId'] as String,
        bowlingTeamName: json['bowlingTeamName'] as String,
        totalRuns: json['totalRuns'] as int? ?? 0,
        wickets: json['wickets'] as int? ?? 0,
        legalBallsBowled: json['legalBallsBowled'] as int? ?? 0,
        currentStrikerId: json['currentStrikerId'] as String?,
        currentNonStrikerId: json['currentNonStrikerId'] as String?,
        currentBowlerId: json['currentBowlerId'] as String?,
        wides: json['wides'] as int? ?? 0,
        noBalls: json['noBalls'] as int? ?? 0,
        byes: json['byes'] as int? ?? 0,
        legByes: json['legByes'] as int? ?? 0,
        penalty: json['penalty'] as int? ?? 0,
        battingScorecards: (json['battingScorecards'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, BatsmanScorecard.fromJson(v as Map<String, dynamic>)),
            ) ??
            {},
        bowlingScorecards: (json['bowlingScorecards'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, BowlerScorecard.fromJson(v as Map<String, dynamic>)),
            ) ??
            {},
        fallOfWickets: (json['fallOfWickets'] as List<dynamic>?)
                ?.map((f) => FallOfWicket.fromJson(f as Map<String, dynamic>))
                .toList() ??
            [],
        overs: (json['overs'] as List<dynamic>?)
                ?.map((o) => OverRecord.fromJson(o as Map<String, dynamic>))
                .toList() ??
            [],
        ballHistory: (json['ballHistory'] as List<dynamic>?)
                ?.map((b) => BallRecord.fromJson(b as Map<String, dynamic>))
                .toList() ??
            [],
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  InningsData deepCopy() {
    return InningsData(
      battingTeamId: battingTeamId,
      battingTeamName: battingTeamName,
      bowlingTeamId: bowlingTeamId,
      bowlingTeamName: bowlingTeamName,
      totalRuns: totalRuns,
      wickets: wickets,
      legalBallsBowled: legalBallsBowled,
      currentStrikerId: currentStrikerId,
      currentNonStrikerId: currentNonStrikerId,
      currentBowlerId: currentBowlerId,
      wides: wides,
      noBalls: noBalls,
      byes: byes,
      legByes: legByes,
      penalty: penalty,
      battingScorecards: battingScorecards.map((k, v) => MapEntry(k, v.copy())),
      bowlingScorecards: bowlingScorecards.map((k, v) => MapEntry(k, v.copy())),
      fallOfWickets: List.from(fallOfWickets),
      overs: overs.map((o) => OverRecord(
        overNumber: o.overNumber,
        bowlerId: o.bowlerId,
        balls: List.from(o.balls),
      )).toList(),
      ballHistory: List.from(ballHistory),
      isCompleted: isCompleted,
    );
  }
}

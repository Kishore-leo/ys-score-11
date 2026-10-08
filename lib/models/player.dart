enum PlayerRole {
  batsman,
  bowler,
  allRounder,
  wicketKeeper,
}

enum BattingStyle {
  rightHand,
  leftHand,
}

enum BowlingStyle {
  rightArmFast,
  rightArmMedium,
  rightArmSpin,
  leftArmFast,
  leftArmMedium,
  leftArmSpin,
  none,
}

class PlayerCareerStats {
  int matches;
  int innings;
  int runs;
  int ballsFaced;
  int highestScore;
  int fifties;
  int hundreds;
  int fours;
  int sixes;
  int notOuts;
  int wickets;
  int runsConceded;
  int ballsBowled;
  int maidens;
  int bestBowlingWickets;
  int bestBowlingRuns;

  PlayerCareerStats({
    this.matches = 0,
    this.innings = 0,
    this.runs = 0,
    this.ballsFaced = 0,
    this.highestScore = 0,
    this.fifties = 0,
    this.hundreds = 0,
    this.fours = 0,
    this.sixes = 0,
    this.notOuts = 0,
    this.wickets = 0,
    this.runsConceded = 0,
    this.ballsBowled = 0,
    this.maidens = 0,
    this.bestBowlingWickets = 0,
    this.bestBowlingRuns = 0,
  });

  double get battingAverage {
    final dismissedTimes = innings - notOuts;
    if (dismissedTimes <= 0) return runs.toDouble();
    return runs / dismissedTimes;
  }

  double get battingStrikeRate {
    if (ballsFaced <= 0) return 0.0;
    return (runs / ballsFaced) * 100.0;
  }

  double get bowlingEconomy {
    if (ballsBowled <= 0) return 0.0;
    final overs = ballsBowled / 6.0;
    return runsConceded / overs;
  }

  double get bowlingAverage {
    if (wickets <= 0) return 0.0;
    return runsConceded / wickets.toDouble();
  }

  String get bestBowlingFigure => '$bestBowlingWickets/$bestBowlingRuns';

  Map<String, dynamic> toJson() => {
        'matches': matches,
        'innings': innings,
        'runs': runs,
        'ballsFaced': ballsFaced,
        'highestScore': highestScore,
        'fifties': fifties,
        'hundreds': hundreds,
        'fours': fours,
        'sixes': sixes,
        'notOuts': notOuts,
        'wickets': wickets,
        'runsConceded': runsConceded,
        'ballsBowled': ballsBowled,
        'maidens': maidens,
        'bestBowlingWickets': bestBowlingWickets,
        'bestBowlingRuns': bestBowlingRuns,
      };

  factory PlayerCareerStats.fromJson(Map<String, dynamic> json) => PlayerCareerStats(
        matches: json['matches'] ?? 0,
        innings: json['innings'] ?? 0,
        runs: json['runs'] ?? 0,
        ballsFaced: json['ballsFaced'] ?? 0,
        highestScore: json['highestScore'] ?? 0,
        fifties: json['fifties'] ?? 0,
        hundreds: json['hundreds'] ?? 0,
        fours: json['fours'] ?? 0,
        sixes: json['sixes'] ?? 0,
        notOuts: json['notOuts'] ?? 0,
        wickets: json['wickets'] ?? 0,
        runsConceded: json['runsConceded'] ?? 0,
        ballsBowled: json['ballsBowled'] ?? 0,
        maidens: json['maidens'] ?? 0,
        bestBowlingWickets: json['bestBowlingWickets'] ?? 0,
        bestBowlingRuns: json['bestBowlingRuns'] ?? 0,
      );
}

class Player {
  final String id;
  String name;
  int jerseyNumber;
  PlayerRole role;
  BattingStyle battingStyle;
  BowlingStyle bowlingStyle;
  String? avatarUrl;
  PlayerCareerStats stats;

  Player({
    required this.id,
    required this.name,
    this.jerseyNumber = 0,
    this.role = PlayerRole.batsman,
    this.battingStyle = BattingStyle.rightHand,
    this.bowlingStyle = BowlingStyle.rightArmMedium,
    this.avatarUrl,
    PlayerCareerStats? stats,
  }) : stats = stats ?? PlayerCareerStats();

  String get roleDisplayName {
    switch (role) {
      case PlayerRole.batsman:
        return 'Batsman';
      case PlayerRole.bowler:
        return 'Bowler';
      case PlayerRole.allRounder:
        return 'All-Rounder';
      case PlayerRole.wicketKeeper:
        return 'Wicketkeeper';
    }
  }

  String get battingStyleDisplayName {
    switch (battingStyle) {
      case BattingStyle.rightHand:
        return 'Right Hand Bat';
      case BattingStyle.leftHand:
        return 'Left Hand Bat';
    }
  }

  String get bowlingStyleDisplayName {
    switch (bowlingStyle) {
      case BowlingStyle.rightArmFast:
        return 'Right Arm Fast';
      case BowlingStyle.rightArmMedium:
        return 'Right Arm Medium';
      case BowlingStyle.rightArmSpin:
        return 'Right Arm Spin';
      case BowlingStyle.leftArmFast:
        return 'Left Arm Fast';
      case BowlingStyle.leftArmMedium:
        return 'Left Arm Medium';
      case BowlingStyle.leftArmSpin:
        return 'Left Arm Spin';
      case BowlingStyle.none:
        return 'None';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'jerseyNumber': jerseyNumber,
        'role': role.index,
        'battingStyle': battingStyle.index,
        'bowlingStyle': bowlingStyle.index,
        'avatarUrl': avatarUrl,
        'stats': stats.toJson(),
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        jerseyNumber: json['jerseyNumber'] as int? ?? 0,
        role: PlayerRole.values[json['role'] as int? ?? 0],
        battingStyle: BattingStyle.values[json['battingStyle'] as int? ?? 0],
        bowlingStyle: BowlingStyle.values[json['bowlingStyle'] as int? ?? 0],
        avatarUrl: json['avatarUrl'] as String?,
        stats: json['stats'] != null ? PlayerCareerStats.fromJson(json['stats']) : null,
      );

  Player copyWith({
    String? id,
    String? name,
    int? jerseyNumber,
    PlayerRole? role,
    BattingStyle? battingStyle,
    BowlingStyle? bowlingStyle,
    String? avatarUrl,
    PlayerCareerStats? stats,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      role: role ?? this.role,
      battingStyle: battingStyle ?? this.battingStyle,
      bowlingStyle: bowlingStyle ?? this.bowlingStyle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      stats: stats ?? this.stats,
    );
  }
}

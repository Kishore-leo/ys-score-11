enum ExtraType {
  none,
  wide,
  noBall,
  bye,
  legBye,
  penalty,
}

enum WicketType {
  bowled,
  caught,
  lbw,
  runOut,
  stumped,
  hitWicket,
  retired,
}

class BallRecord {
  final String id;
  final int ballNumberInInnings;
  final int overNumber; // 0-indexed (e.g. 0 for first over, 11 for 12th over)
  final int ballNumberInOver; // 1 to 6 for legal deliveries
  final bool isLegal;
  final String batsmanId;
  final String nonStrikerId;
  final String bowlerId;
  final int runsScored; // Off the bat
  final ExtraType extraType;
  final int extraRuns; // 1 for wide/nb plus any running runs
  final bool isWicket;
  final WicketType? wicketType;
  final String? dismissedPlayerId;
  final String? fielderId;
  final String commentary;

  BallRecord({
    required this.id,
    required this.ballNumberInInnings,
    required this.overNumber,
    required this.ballNumberInOver,
    required this.isLegal,
    required this.batsmanId,
    required this.nonStrikerId,
    required this.bowlerId,
    this.runsScored = 0,
    this.extraType = ExtraType.none,
    this.extraRuns = 0,
    this.isWicket = false,
    this.wicketType,
    this.dismissedPlayerId,
    this.fielderId,
    required this.commentary,
  });

  int get totalRuns => runsScored + extraRuns;

  bool get isFour => runsScored == 4 && extraType != ExtraType.bye && extraType != ExtraType.legBye;
  bool get isSix => runsScored == 6 && extraType != ExtraType.bye && extraType != ExtraType.legBye;

  String get shortDisplay {
    if (isWicket) {
      if (runsScored > 0) return 'W+$runsScored';
      return 'W';
    }
    switch (extraType) {
      case ExtraType.wide:
        return extraRuns > 1 ? '${extraRuns}wd' : 'wd';
      case ExtraType.noBall:
        return runsScored > 0 ? 'nb+$runsScored' : 'nb';
      case ExtraType.bye:
        return '${extraRuns}b';
      case ExtraType.legBye:
        return '${extraRuns}lb';
      case ExtraType.penalty:
        return '${extraRuns}p';
      case ExtraType.none:
        return '$runsScored';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ballNumberInInnings': ballNumberInInnings,
        'overNumber': overNumber,
        'ballNumberInOver': ballNumberInOver,
        'isLegal': isLegal,
        'batsmanId': batsmanId,
        'nonStrikerId': nonStrikerId,
        'bowlerId': bowlerId,
        'runsScored': runsScored,
        'extraType': extraType.index,
        'extraRuns': extraRuns,
        'isWicket': isWicket,
        'wicketType': wicketType?.index,
        'dismissedPlayerId': dismissedPlayerId,
        'fielderId': fielderId,
        'commentary': commentary,
      };

  factory BallRecord.fromJson(Map<String, dynamic> json) => BallRecord(
        id: json['id'] as String,
        ballNumberInInnings: json['ballNumberInInnings'] as int,
        overNumber: json['overNumber'] as int,
        ballNumberInOver: json['ballNumberInOver'] as int,
        isLegal: json['isLegal'] as bool? ?? true,
        batsmanId: json['batsmanId'] as String,
        nonStrikerId: json['nonStrikerId'] as String,
        bowlerId: json['bowlerId'] as String,
        runsScored: json['runsScored'] as int? ?? 0,
        extraType: ExtraType.values[json['extraType'] as int? ?? 0],
        extraRuns: json['extraRuns'] as int? ?? 0,
        isWicket: json['isWicket'] as bool? ?? false,
        wicketType: json['wicketType'] != null
            ? WicketType.values[json['wicketType'] as int]
            : null,
        dismissedPlayerId: json['dismissedPlayerId'] as String?,
        fielderId: json['fielderId'] as String?,
        commentary: json['commentary'] as String? ?? '',
      );
}

import 'ball_record.dart';

class OverRecord {
  final int overNumber; // 0-indexed
  final String bowlerId;
  final List<BallRecord> balls;

  OverRecord({
    required this.overNumber,
    required this.bowlerId,
    List<BallRecord>? balls,
  }) : balls = balls ?? [];

  int get legalBallCount => balls.where((b) => b.isLegal).length;
  bool get isCompleted => legalBallCount >= 6;

  int get totalRuns => balls.fold(0, (sum, b) => sum + b.totalRuns);
  int get wickets => balls.where((b) => b.isWicket).length;

  // Maiden: exactly 6 legal deliveries and 0 runs conceded by the bowler (byes and leg byes do not count against bowler)
  bool get isMaiden {
    if (!isCompleted) return false;
    final runsChargedToBowler = balls.fold(0, (sum, b) {
      if (b.extraType == ExtraType.bye || b.extraType == ExtraType.legBye) {
        return sum; // Not charged to bowler
      }
      return sum + b.totalRuns;
    });
    return runsChargedToBowler == 0;
  }

  Map<String, dynamic> toJson() => {
        'overNumber': overNumber,
        'bowlerId': bowlerId,
        'balls': balls.map((b) => b.toJson()).toList(),
      };

  factory OverRecord.fromJson(Map<String, dynamic> json) => OverRecord(
        overNumber: json['overNumber'] as int,
        bowlerId: json['bowlerId'] as String,
        balls: (json['balls'] as List<dynamic>?)
                ?.map((b) => BallRecord.fromJson(b as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

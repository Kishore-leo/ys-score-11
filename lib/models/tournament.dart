class PointsTableRow {
  final String teamId;
  String teamName;
  int played;
  int won;
  int lost;
  int tied;
  int noResult;
  int points;
  int runsScored;
  double oversFaced; // in fractional overs e.g. 19.4 = 19 + 4/6
  int runsConceded;
  double oversBowled;

  PointsTableRow({
    required this.teamId,
    required this.teamName,
    this.played = 0,
    this.won = 0,
    this.lost = 0,
    this.tied = 0,
    this.noResult = 0,
    this.points = 0,
    this.runsScored = 0,
    this.oversFaced = 0.0,
    this.runsConceded = 0,
    this.oversBowled = 0.0,
  });

  double get netRunRate {
    final forRate = oversFaced > 0 ? runsScored / oversFaced : 0.0;
    final againstRate = oversBowled > 0 ? runsConceded / oversBowled : 0.0;
    return forRate - againstRate;
  }

  String get nrrString {
    final nrr = netRunRate;
    final sign = nrr > 0 ? '+' : '';
    return '$sign${nrr.toStringAsFixed(3)}';
  }

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'teamName': teamName,
        'played': played,
        'won': won,
        'lost': lost,
        'tied': tied,
        'noResult': noResult,
        'points': points,
        'runsScored': runsScored,
        'oversFaced': oversFaced,
        'runsConceded': runsConceded,
        'oversBowled': oversBowled,
      };

  factory PointsTableRow.fromJson(Map<String, dynamic> json) => PointsTableRow(
        teamId: json['teamId'] as String,
        teamName: json['teamName'] as String,
        played: json['played'] as int? ?? 0,
        won: json['won'] as int? ?? 0,
        lost: json['lost'] as int? ?? 0,
        tied: json['tied'] as int? ?? 0,
        noResult: json['noResult'] as int? ?? 0,
        points: json['points'] as int? ?? 0,
        runsScored: json['runsScored'] as int? ?? 0,
        oversFaced: (json['oversFaced'] as num?)?.toDouble() ?? 0.0,
        runsConceded: json['runsConceded'] as int? ?? 0,
        oversBowled: (json['oversBowled'] as num?)?.toDouble() ?? 0.0,
      );
}

class Tournament {
  final String id;
  String name;
  String location;
  DateTime startDate;
  DateTime endDate;
  List<String> teamIds;
  List<String> matchIds;
  List<PointsTableRow> pointsTable;

  Tournament({
    required this.id,
    required this.name,
    this.location = '',
    required this.startDate,
    required this.endDate,
    List<String>? teamIds,
    List<String>? matchIds,
    List<PointsTableRow>? pointsTable,
  })  : teamIds = teamIds ?? [],
        matchIds = matchIds ?? [],
        pointsTable = pointsTable ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'teamIds': teamIds,
        'matchIds': matchIds,
        'pointsTable': pointsTable.map((p) => p.toJson()).toList(),
      };

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
        id: json['id'] as String,
        name: json['name'] as String,
        location: json['location'] as String? ?? '',
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        teamIds: (json['teamIds'] as List<dynamic>?)?.cast<String>() ?? [],
        matchIds: (json['matchIds'] as List<dynamic>?)?.cast<String>() ?? [],
        pointsTable: (json['pointsTable'] as List<dynamic>?)
                ?.map((p) => PointsTableRow.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

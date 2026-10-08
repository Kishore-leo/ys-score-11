import 'player.dart';

class Team {
  final String id;
  String name;
  String shortName;
  String colorHex; // e.g. '#00E676'
  String? logoUrl;
  String? captainId;
  String? viceCaptainId;
  List<Player> players;

  Team({
    required this.id,
    required this.name,
    required this.shortName,
    this.colorHex = '#00E676',
    this.logoUrl,
    this.captainId,
    this.viceCaptainId,
    List<Player>? players,
  }) : players = players ?? [];

  Player? get captain => players.cast<Player?>().firstWhere(
        (p) => p?.id == captainId,
        orElse: () => null,
      );

  Player? get viceCaptain => players.cast<Player?>().firstWhere(
        (p) => p?.id == viceCaptainId,
        orElse: () => null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'shortName': shortName,
        'colorHex': colorHex,
        'logoUrl': logoUrl,
        'captainId': captainId,
        'viceCaptainId': viceCaptainId,
        'players': players.map((p) => p.toJson()).toList(),
      };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        name: json['name'] as String,
        shortName: json['shortName'] as String,
        colorHex: json['colorHex'] as String? ?? '#00E676',
        logoUrl: json['logoUrl'] as String?,
        captainId: json['captainId'] as String?,
        viceCaptainId: json['viceCaptainId'] as String?,
        players: (json['players'] as List<dynamic>?)
                ?.map((p) => Player.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Team copyWith({
    String? id,
    String? name,
    String? shortName,
    String? colorHex,
    String? logoUrl,
    String? captainId,
    String? viceCaptainId,
    List<Player>? players,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      colorHex: colorHex ?? this.colorHex,
      logoUrl: logoUrl ?? this.logoUrl,
      captainId: captainId ?? this.captainId,
      viceCaptainId: viceCaptainId ?? this.viceCaptainId,
      players: players ?? List.from(this.players),
    );
  }
}

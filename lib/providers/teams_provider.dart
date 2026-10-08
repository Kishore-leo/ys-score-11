import 'package:flutter/foundation.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../services/storage_service.dart';
import '../services/mock_data_service.dart';

class TeamsProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<Team> _teams = [];
  bool _isLoading = false;

  List<Team> get teams => _teams;
  bool get isLoading => _isLoading;

  Future<void> loadTeams() async {
    _isLoading = true;
    notifyListeners();
    var loaded = await _storage.loadTeams();
    if (loaded.isEmpty) {
      loaded = MockDataService.getInitialTeams();
      await _storage.saveTeams(loaded);
    }
    _teams = loaded;
    _isLoading = false;
    notifyListeners();
  }

  Team? getTeamById(String id) {
    try {
      return _teams.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Player? getPlayerById(String playerId) {
    for (final team in _teams) {
      for (final player in team.players) {
        if (player.id == playerId) return player;
      }
    }
    return null;
  }

  Future<Team> createTeam({
    required String name,
    required String shortName,
    String colorHex = '#00E676',
    String? captainId,
    String? viceCaptainId,
    List<Player>? players,
  }) async {
    final newTeam = Team(
      id: 'team_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      shortName: shortName.toUpperCase(),
      colorHex: colorHex,
      captainId: captainId,
      viceCaptainId: viceCaptainId,
      players: players ?? [],
    );
    _teams.add(newTeam);
    await _storage.saveTeams(_teams);
    notifyListeners();
    return newTeam;
  }

  Future<void> updateTeam(Team team) async {
    final index = _teams.indexWhere((t) => t.id == team.id);
    if (index >= 0) {
      _teams[index] = team;
      await _storage.saveTeams(_teams);
      notifyListeners();
    }
  }

  Future<void> deleteTeam(String teamId) async {
    _teams.removeWhere((t) => t.id == teamId);
    await _storage.saveTeams(_teams);
    notifyListeners();
  }

  Future<Player> addPlayerToTeam(String teamId, Player player) async {
    final team = getTeamById(teamId);
    if (team == null) return player;
    team.players.add(player);
    await _storage.saveTeams(_teams);
    notifyListeners();
    return player;
  }

  Future<void> updatePlayerInTeam(String teamId, Player updatedPlayer) async {
    final team = getTeamById(teamId);
    if (team == null) return;
    final index = team.players.indexWhere((p) => p.id == updatedPlayer.id);
    if (index >= 0) {
      team.players[index] = updatedPlayer;
      await _storage.saveTeams(_teams);
      notifyListeners();
    }
  }

  Future<void> removePlayerFromTeam(String teamId, String playerId) async {
    final team = getTeamById(teamId);
    if (team == null) return;
    team.players.removeWhere((p) => p.id == playerId);
    await _storage.saveTeams(_teams);
    notifyListeners();
  }

  // Update career statistics from completed match
  Future<void> applyMatchStats({
    required Map<String, dynamic> battingScores,
    required Map<String, dynamic> bowlingScores,
  }) async {
    bool changed = false;
    for (final team in _teams) {
      for (final player in team.players) {
        if (battingScores.containsKey(player.id)) {
          final bat = battingScores[player.id];
          player.stats.matches += 1;
          player.stats.innings += 1;
          player.stats.runs += (bat['runs'] as int? ?? 0);
          player.stats.ballsFaced += (bat['balls'] as int? ?? 0);
          player.stats.fours += (bat['fours'] as int? ?? 0);
          player.stats.sixes += (bat['sixes'] as int? ?? 0);
          if (!(bat['isOut'] as bool? ?? false)) {
            player.stats.notOuts += 1;
          }
          final r = bat['runs'] as int? ?? 0;
          if (r > player.stats.highestScore) player.stats.highestScore = r;
          if (r >= 100) {
            player.stats.hundreds += 1;
          } else if (r >= 50) {
            player.stats.fifties += 1;
          }
          changed = true;
        }

        if (bowlingScores.containsKey(player.id)) {
          final bowl = bowlingScores[player.id];
          if (!battingScores.containsKey(player.id)) {
            player.stats.matches += 1;
          }
          final balls = (bowl['legalBallsBowled'] as int? ?? 0);
          final runsConceded = (bowl['runsConceded'] as int? ?? 0);
          final wickets = (bowl['wickets'] as int? ?? 0);
          final maidens = (bowl['maidens'] as int? ?? 0);

          player.stats.ballsBowled += balls;
          player.stats.runsConceded += runsConceded;
          player.stats.wickets += wickets;
          player.stats.maidens += maidens;

          if (wickets > player.stats.bestBowlingWickets ||
              (wickets == player.stats.bestBowlingWickets && runsConceded < player.stats.bestBowlingRuns)) {
            player.stats.bestBowlingWickets = wickets;
            player.stats.bestBowlingRuns = runsConceded;
          }
          changed = true;
        }
      }
    }
    if (changed) {
      await _storage.saveTeams(_teams);
      notifyListeners();
    }
  }
}

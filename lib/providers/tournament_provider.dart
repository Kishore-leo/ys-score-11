import 'package:flutter/foundation.dart';
import '../models/tournament.dart';
import '../models/team.dart';
import '../models/cricket_match.dart';
import '../services/storage_service.dart';

class TournamentProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<Tournament> _tournaments = [];
  bool _isLoading = false;

  List<Tournament> get tournaments => _tournaments;
  bool get isLoading => _isLoading;

  Future<void> loadTournaments(List<Team> availableTeams) async {
    _isLoading = true;
    notifyListeners();
    var loaded = await _storage.loadTournaments();
    if (loaded.isEmpty && availableTeams.length >= 2) {
      // Create initial sample tournament: Young Storms Super Series
      final initial = Tournament(
        id: 'tournament_ys_super_series',
        name: 'Young Storms Super League 2026',
        location: 'Young Storms Cricket Arena',
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 7)),
        teamIds: availableTeams.take(3).map((t) => t.id).toList(),
        pointsTable: [
          PointsTableRow(
            teamId: availableTeams[0].id,
            teamName: availableTeams[0].name,
            played: 2,
            won: 2,
            lost: 0,
            points: 4,
            runsScored: 360,
            oversFaced: 40.0,
            runsConceded: 310,
            oversBowled: 40.0,
          ),
          if (availableTeams.length > 1)
            PointsTableRow(
              teamId: availableTeams[1].id,
              teamName: availableTeams[1].name,
              played: 2,
              won: 1,
              lost: 1,
              points: 2,
              runsScored: 325,
              oversFaced: 40.0,
              runsConceded: 330,
              oversBowled: 40.0,
            ),
          if (availableTeams.length > 2)
            PointsTableRow(
              teamId: availableTeams[2].id,
              teamName: availableTeams[2].name,
              played: 2,
              won: 0,
              lost: 2,
              points: 0,
              runsScored: 290,
              oversFaced: 40.0,
              runsConceded: 335,
              oversBowled: 40.0,
            ),
        ],
      );
      loaded = [initial];
      await _storage.saveTournaments(loaded);
    }
    _tournaments = loaded;
    _isLoading = false;
    notifyListeners();
  }

  Tournament? getTournamentById(String id) {
    try {
      return _tournaments.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Tournament> createTournament({
    required String name,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required List<Team> teams,
  }) async {
    final rows = teams
        .map((t) => PointsTableRow(teamId: t.id, teamName: t.name))
        .toList();

    final tourney = Tournament(
      id: 'tourney_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      location: location,
      startDate: startDate,
      endDate: endDate,
      teamIds: teams.map((t) => t.id).toList(),
      pointsTable: rows,
    );

    _tournaments.add(tourney);
    await _storage.saveTournaments(_tournaments);
    notifyListeners();
    return tourney;
  }

  Future<void> recordMatchInTournament({
    required String tournamentId,
    required CricketMatch match,
  }) async {
    final tourney = getTournamentById(tournamentId);
    if (tourney == null || match.status != MatchStatus.completed) return;

    if (!tourney.matchIds.contains(match.id)) {
      tourney.matchIds.add(match.id);
    }

    final rowA = tourney.pointsTable.firstWhere((r) => r.teamId == match.teamA.id,
        orElse: () => PointsTableRow(teamId: match.teamA.id, teamName: match.teamA.name));
    final rowB = tourney.pointsTable.firstWhere((r) => r.teamId == match.teamB.id,
        orElse: () => PointsTableRow(teamId: match.teamB.id, teamName: match.teamB.name));

    rowA.played += 1;
    rowB.played += 1;

    if (match.winnerTeamId == match.teamA.id) {
      rowA.won += 1;
      rowA.points += 2;
      rowB.lost += 1;
    } else if (match.winnerTeamId == match.teamB.id) {
      rowB.won += 1;
      rowB.points += 2;
      rowA.lost += 1;
    } else {
      rowA.tied += 1;
      rowB.tied += 1;
      rowA.points += 1;
      rowB.points += 1;
    }

    // Accumulate runs and overs for NRR
    if (match.innings1 != null && match.innings2 != null) {
      final isTeamABatFirst = match.battingFirstTeamId == match.teamA.id;
      final innA = isTeamABatFirst ? match.innings1! : match.innings2!;
      final innB = isTeamABatFirst ? match.innings2! : match.innings1!;

      rowA.runsScored += innA.totalRuns;
      rowA.oversFaced += (innA.legalBallsBowled / 6.0);
      rowA.runsConceded += innB.totalRuns;
      rowA.oversBowled += (innB.legalBallsBowled / 6.0);

      rowB.runsScored += innB.totalRuns;
      rowB.oversFaced += (innB.legalBallsBowled / 6.0);
      rowB.runsConceded += innA.totalRuns;
      rowB.oversBowled += (innA.legalBallsBowled / 6.0);
    }

    // Sort table by points descending, then NRR descending
    tourney.pointsTable.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      return b.netRunRate.compareTo(a.netRunRate);
    });

    await _storage.saveTournaments(_tournaments);
    notifyListeners();
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cricket_match.dart';
import '../models/team.dart';
import '../models/tournament.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _keyMatches = 'ys_score_matches';
  static const String _keyTeams = 'ys_score_teams';
  static const String _keyTournaments = 'ys_score_tournaments';
  static const String _keyUser = 'ys_score_user';
  static const String _keyActiveMatchId = 'ys_score_active_match_id';

  // Matches
  Future<List<CricketMatch>> loadMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyMatches);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((m) => CricketMatch.fromJson(m as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveMatches(List<CricketMatch> matches) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(matches.map((m) => m.toJson()).toList());
    await prefs.setString(_keyMatches, raw);
  }

  Future<void> saveSingleMatch(CricketMatch match) async {
    final matches = await loadMatches();
    final index = matches.indexWhere((m) => m.id == match.id);
    if (index >= 0) {
      matches[index] = match;
    } else {
      matches.insert(0, match);
    }
    await saveMatches(matches);
  }

  Future<void> deleteMatch(String matchId) async {
    final matches = await loadMatches();
    matches.removeWhere((m) => m.id == matchId);
    await saveMatches(matches);
  }

  // Active match
  Future<String?> getActiveMatchId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveMatchId);
  }

  Future<void> setActiveMatchId(String? matchId) async {
    final prefs = await SharedPreferences.getInstance();
    if (matchId == null) {
      await prefs.remove(_keyActiveMatchId);
    } else {
      await prefs.setString(_keyActiveMatchId, matchId);
    }
  }

  // Teams
  Future<List<Team>> loadTeams() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTeams);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((t) => Team.fromJson(t as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveTeams(List<Team> teams) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(teams.map((t) => t.toJson()).toList());
    await prefs.setString(_keyTeams, raw);
  }

  Future<void> saveSingleTeam(Team team) async {
    final teams = await loadTeams();
    final index = teams.indexWhere((t) => t.id == team.id);
    if (index >= 0) {
      teams[index] = team;
    } else {
      teams.add(team);
    }
    await saveTeams(teams);
  }

  // Tournaments
  Future<List<Tournament>> loadTournaments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTournaments);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((t) => Tournament.fromJson(t as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveTournaments(List<Tournament> tournaments) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(tournaments.map((t) => t.toJson()).toList());
    await prefs.setString(_keyTournaments, raw);
  }

  // User Profile & Session
  Future<UserModel?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
  }
}

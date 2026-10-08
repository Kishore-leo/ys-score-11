import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/scoring_provider.dart';
import '../../providers/teams_provider.dart';
import '../../models/player.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scoring = context.watch<ScoringProvider>();
    final teamsProvider = context.watch<TeamsProvider>();

    final completedMatches = scoring.completedMatches;

    // Collect all players sorted by runs and wickets
    final allPlayers = <Player>[];
    for (final team in teamsProvider.teams) {
      allPlayers.addAll(team.players);
    }

    final topRunScorers = List<Player>.from(allPlayers)
      ..sort((a, b) => b.stats.runs.compareTo(a.stats.runs));

    final topWicketTakers = List<Player>.from(allPlayers)
      ..sort((a, b) => b.stats.wickets.compareTo(a.stats.wickets));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('STATISTICS DASHBOARD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Matches Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _buildSummaryItem('TOTAL MATCHES', '${scoring.matches.length}', AppColors.accent),
                  _buildSummaryItem('COMPLETED', '${completedMatches.length}', AppColors.cyan),
                  _buildSummaryItem('TEAMS', '${teamsProvider.teams.length}', AppColors.amber),
                  _buildSummaryItem('PLAYERS', '${allPlayers.length}', Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Top Run Scorers Leaderboard
            _buildSectionTitle('TOP RUN SCORERS', Icons.sports_cricket_rounded, AppColors.accent),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: topRunScorers.take(5).toList().asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: idx == 0 ? AppColors.gold : AppColors.surface,
                      child: Text('${idx + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: idx == 0 ? Colors.black : Colors.white)),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text('${p.stats.innings} Innings • Avg: ${p.stats.battingAverage.toStringAsFixed(1)} • SR: ${p.stats.battingStrikeRate.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    trailing: Text('${p.stats.runs} R', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.accent)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Top Wicket Takers Leaderboard
            _buildSectionTitle('TOP WICKET TAKERS', Icons.sports_baseball_rounded, AppColors.cyan),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: topWicketTakers.take(5).toList().asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: idx == 0 ? AppColors.cyan : AppColors.surface,
                      child: Text('${idx + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: idx == 0 ? Colors.black : Colors.white)),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text('${p.stats.ballsBowled ~/ 6} Overs • Econ: ${p.stats.bowlingEconomy.toStringAsFixed(2)} • Best: ${p.stats.bestBowlingFigure}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    trailing: Text('${p.stats.wickets} W', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.cyan)),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8)),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String val, Color valColor) {
    return Expanded(
      child: Column(
        children: [
          Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: valColor)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

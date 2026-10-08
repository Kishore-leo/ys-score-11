import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/player.dart';

class PlayerProfileScreen extends StatelessWidget {
  final Player player;
  final String teamName;

  const PlayerProfileScreen({super.key, required this.player, required this.teamName});

  @override
  Widget build(BuildContext context) {
    final stats = player.stats;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(player.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Player Profile Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.accent.withOpacity(0.2),
                    child: Text(
                      '#${player.jerseyNumber}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.accent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(player.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(teamName, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildChip(player.roleDisplayName),
                      _buildChip(player.battingStyleDisplayName),
                      if (player.bowlingStyle != BowlingStyle.none)
                        _buildChip(player.bowlingStyleDisplayName),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // BATTING CAREER STATS
            _buildStatHeader('BATTING CAREER STATS', Icons.sports_cricket_rounded),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildStatBox('MATCHES', '${stats.matches}'),
                      _buildStatBox('INNINGS', '${stats.innings}'),
                      _buildStatBox('RUNS', '${stats.runs}', highlight: true),
                      _buildStatBox('HS', '${stats.highestScore}'),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 20),
                  Row(
                    children: [
                      _buildStatBox('AVERAGE', stats.battingAverage.toStringAsFixed(1)),
                      _buildStatBox('STRIKE RATE', stats.battingStrikeRate.toStringAsFixed(1)),
                      _buildStatBox('50s', '${stats.fifties}'),
                      _buildStatBox('100s', '${stats.hundreds}'),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 20),
                  Row(
                    children: [
                      _buildStatBox('FOURS (4s)', '${stats.fours}'),
                      _buildStatBox('SIXES (6s)', '${stats.sixes}'),
                      _buildStatBox('NOT OUTS', '${stats.notOuts}'),
                      _buildStatBox('BALLS FACED', '${stats.ballsFaced}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // BOWLING CAREER STATS
            _buildStatHeader('BOWLING CAREER STATS', Icons.sports_baseball_rounded),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildStatBox('OVERS', '${stats.ballsBowled ~/ 6}.${stats.ballsBowled % 6}'),
                      _buildStatBox('WICKETS', '${stats.wickets}', highlight: true),
                      _buildStatBox('ECONOMY', stats.bowlingEconomy.toStringAsFixed(2)),
                      _buildStatBox('MAIDENS', '${stats.maidens}'),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 20),
                  Row(
                    children: [
                      _buildStatBox('BEST FIGURES', stats.bestBowlingFigure),
                      _buildStatBox('RUNS GIVEN', '${stats.runsConceded}'),
                      _buildStatBox('BOWLING AVG', stats.bowlingAverage.toStringAsFixed(1)),
                      _buildStatBox('BALLS BOWLED', '${stats.ballsBowled}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8)),
      ],
    );
  }

  Widget _buildStatBox(String label, String val, {bool highlight = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: highlight ? AppColors.accent : Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

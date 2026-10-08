import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/cricket_match.dart';
import '../../models/player.dart';
import 'scorecard_screen.dart';
import '../ai_prediction/ai_prediction_screen.dart';
import '../home/home_screen.dart';

class MatchResultScreen extends StatelessWidget {
  final CricketMatch match;

  const MatchResultScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final allPlayers = [...match.teamA.players, ...match.teamB.players];
    final pom = match.playerOfTheMatchId != null
        ? allPlayers.cast<Player?>().firstWhere((p) => p?.id == match.playerOfTheMatchId, orElse: () => null)
        : null;

    final inn1 = match.innings1;
    final inn2 = match.innings2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MATCH RESULT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Winner Trophy Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF193226), Color(0xFF101B2B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(color: AppColors.accent.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.15),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.premiumGoldGradient,
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Colors.black, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    match.resultSummary?.toUpperCase() ?? 'MATCH CONCLUDED',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${match.name} • ${match.venue}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Scores Comparison
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  if (inn1 != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(inn1.battingTeamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                        Text(
                          '${inn1.totalRuns}/${inn1.wickets} (${inn1.oversString} Ov)',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                  if (inn2 != null) ...[
                    const Divider(color: AppColors.border, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(inn2.battingTeamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                        Text(
                          '${inn2.totalRuns}/${inn2.wickets} (${inn2.oversString} Ov)',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Player of the Match Card
            if (pom != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold.withOpacity(0.2),
                        border: Border.all(color: AppColors.gold),
                      ),
                      child: const Center(
                        child: Icon(Icons.star_rounded, color: AppColors.gold, size: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PLAYER OF THE MATCH',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.gold, letterSpacing: 1.0),
                          ),
                          Text(
                            pom.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          Text(
                            '#${pom.jerseyNumber} • ${pom.roleDisplayName}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.table_chart_rounded, size: 20),
                label: const Text('VIEW FULL SCORECARD', style: TextStyle(fontWeight: FontWeight.w900)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ScorecardScreen(match: match)),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: const Icon(Icons.psychology_rounded, size: 20, color: AppColors.cyan),
                label: const Text('AI MATCH ANALYSIS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.cyan)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AiPredictionScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('Back to Home', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

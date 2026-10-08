import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/cricket_match.dart';
import '../../models/innings_data.dart';

class ScorecardScreen extends StatelessWidget {
  final CricketMatch match;

  const ScorecardScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final hasInnings2 = match.innings2 != null;

    return DefaultTabController(
      length: hasInnings2 ? 2 : 1,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(match.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          bottom: TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: '${match.innings1?.battingTeamName ?? "1st Innings"} (Inn 1)'),
              if (hasInnings2)
                Tab(text: '${match.innings2?.battingTeamName ?? "2nd Innings"} (Inn 2)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            if (match.innings1 != null)
              _buildInningsScorecard(context, match.innings1!, match.totalOvers)
            else
              const Center(child: Text('No 1st innings data')),
            if (hasInnings2)
              _buildInningsScorecard(context, match.innings2!, match.totalOvers),
          ],
        ),
      ),
    );
  }

  Widget _buildInningsScorecard(BuildContext context, InningsData innings, int totalOvers) {
    final batsmen = innings.battingScorecards.values.toList()
      ..sort((a, b) => a.battingOrder.compareTo(b.battingOrder));
    final bowlers = innings.bowlingScorecards.values.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Score Header Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      innings.battingTeamName.toUpperCase(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    Text(
                      'Overs: ${innings.oversString} / $totalOvers',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${innings.totalRuns} / ${innings.wickets}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.accent),
                    ),
                    Text(
                      'CRR: ${innings.currentRunRate.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // BATTING SECTION
          _buildSectionTitle('BATTING', Icons.sports_cricket_rounded),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Table Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: const [
                      Expanded(flex: 4, child: Text('BATSMAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted))),
                      Expanded(flex: 1, child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted))),
                      Expanded(flex: 1, child: Text('B', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted))),
                      Expanded(flex: 1, child: Text('4s', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted))),
                      Expanded(flex: 1, child: Text('6s', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted))),
                      Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted))),
                    ],
                  ),
                ),
                const Divider(color: AppColors.border, height: 1),
                ...batsmen.map((b) => _buildBatsmanTile(b)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // EXTRAS & TOTAL
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Extras', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(
                      '${innings.totalExtras} (wd ${innings.wides}, nb ${innings.noBalls}, b ${innings.byes}, lb ${innings.legByes})',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Score', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.accent)),
                    Text(
                      '${innings.totalRuns} / ${innings.wickets} (${innings.oversString} Overs, RR: ${innings.currentRunRate.toStringAsFixed(2)})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // BOWLING SECTION
          _buildSectionTitle('BOWLING', Icons.sports_baseball_rounded),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: const [
                      Expanded(flex: 4, child: Text('BOWLER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted))),
                      Expanded(flex: 1, child: Text('O', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted))),
                      Expanded(flex: 1, child: Text('M', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted))),
                      Expanded(flex: 1, child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted))),
                      Expanded(flex: 1, child: Text('W', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted))),
                      Expanded(flex: 2, child: Text('ECON', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted))),
                    ],
                  ),
                ),
                const Divider(color: AppColors.border, height: 1),
                ...bowlers.map((b) => _buildBowlerTile(b)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // FALL OF WICKETS
          if (innings.fallOfWickets.isNotEmpty) ...[
            _buildSectionTitle('FALL OF WICKETS', Icons.stairs_rounded),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: innings.fallOfWickets.map((f) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${f.score}/${f.wicketNumber} (${f.batsmanName})',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${f.overs} Ov',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8),
        ),
      ],
    );
  }

  Widget _buildBatsmanTile(BatsmanScorecard b) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.playerName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                Text(b.dismissalText, style: TextStyle(color: b.isOut ? AppColors.textMuted : AppColors.accent, fontSize: 11)),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text('${b.runs}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13))),
          Expanded(flex: 1, child: Text('${b.balls}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          Expanded(flex: 1, child: Text('${b.fours}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          Expanded(flex: 1, child: Text('${b.sixes}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          Expanded(flex: 2, child: Text(b.strikeRate.toStringAsFixed(1), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildBowlerTile(BowlerScorecard b) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(b.playerName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
          ),
          Expanded(flex: 1, child: Text(b.oversString, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13))),
          Expanded(flex: 1, child: Text('${b.maidens}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          Expanded(flex: 1, child: Text('${b.runsConceded}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          Expanded(flex: 1, child: Text('${b.wickets}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.danger, fontSize: 13))),
          Expanded(flex: 2, child: Text(b.economy.toStringAsFixed(2), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scoring_provider.dart';
import '../../models/cricket_match.dart';
import '../match_creation/create_match_wizard.dart';
import '../scoring/scoring_screen.dart';
import '../scoring/scorecard_screen.dart';
import '../scoring/match_result_screen.dart';
import '../teams/teams_screen.dart';
import '../players/players_screen.dart';
import '../tournament/tournament_screen.dart';
import '../ai_prediction/ai_prediction_screen.dart';
import '../statistics/statistics_screen.dart';
import '../premium/premium_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scoring = context.watch<ScoringProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.accentGradient,
              ),
              child: const Icon(Icons.sports_cricket_rounded, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'YS SCORE 11',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 18),
            ),
          ],
        ),
        actions: [
          if (auth.isPremium)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.premiumGoldGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 14),
                  SizedBox(width: 4),
                  Text('PRO', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, size: 26),
        label: const Text(
          '+ CREATE MATCH',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.0),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateMatchWizard()),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 18, right: 18, top: 12, bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent Hero CTA Card
            _buildHeroCta(context),
            const SizedBox(height: 24),

            // Live / In-Progress Matches
            if (scoring.liveMatches.isNotEmpty) ...[
              _buildSectionHeader('Live / Running Matches', Icons.fiber_manual_record_rounded, Colors.redAccent),
              const SizedBox(height: 10),
              ...scoring.liveMatches.map((m) => _buildLiveMatchCard(context, m, scoring)),
              const SizedBox(height: 20),
            ],

            // Quick Hub Navigation Cards
            _buildSectionHeader('Cricket Hub', Icons.grid_view_rounded, AppColors.accent),
            const SizedBox(height: 12),
            _buildQuickNavGrid(context, auth),
            const SizedBox(height: 24),

            // Recent Completed Matches
            _buildSectionHeader('Recent Matches', Icons.history_rounded, AppColors.cyan),
            const SizedBox(height: 12),
            if (scoring.completedMatches.isEmpty)
              _buildEmptyState('No completed matches yet. Start scoring your first ground match!')
            else
              ...scoring.completedMatches.take(5).map((m) => _buildCompletedMatchCard(context, m)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCta(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF162A2B), Color(0xFF121B2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.accent.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.12),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 14, color: AppColors.accent),
                    SizedBox(width: 4),
                    Text(
                      'READY TO SCORE',
                      style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text('Young Storms', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Start a Ground Match',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create custom teams, select playing XI, set toss, and score ball-by-ball with full undo.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: const Text(
                '+ CREATE NEW MATCH',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateMatchWizard()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveMatchCard(BuildContext context, CricketMatch match, ScoringProvider scoring) {
    final currentInn = match.currentInnings;
    final isInn2 = match.status == MatchStatus.inning2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            scoring.setActiveMatch(match);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ScoringScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.fiber_manual_record_rounded, size: 10, color: Colors.redAccent),
                          SizedBox(width: 4),
                          Text('LIVE SCORING', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(match.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${match.totalOvers} Ov', style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentInn?.battingTeamName ?? match.teamA.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'vs ${currentInn?.bowlingTeamName ?? match.teamB.name}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${currentInn?.totalRuns ?? 0} / ${currentInn?.wickets ?? 0}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.accent),
                        ),
                        Text(
                          '(${currentInn?.oversString ?? "0.0"} / ${match.totalOvers} Ov)',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isInn2 && match.targetRuns != null) ...[
                  const Divider(color: AppColors.border, height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target: ${match.targetRuns} | Need ${match.requiredRuns} off ${match.remainingBalls}b',
                        style: const TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'RRR: ${match.requiredRunRate?.toStringAsFixed(2) ?? "-"}',
                        style: const TextStyle(color: AppColors.cyan, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.sports_cricket_rounded, size: 16, color: AppColors.accent),
                      label: const Text('RESUME SCORING', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w800)),
                      onPressed: () {
                        scoring.setActiveMatch(match);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ScoringScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickNavGrid(BuildContext context, AuthProvider auth) {
    final navItems = [
      _NavGridItem(
        title: 'My Teams',
        subtitle: 'Manage squads & logos',
        icon: Icons.groups_rounded,
        color: const Color(0xFF00E676),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeamsScreen())),
      ),
      _NavGridItem(
        title: 'My Players',
        subtitle: 'Career stats & averages',
        icon: Icons.person_search_rounded,
        color: const Color(0xFF2979FF),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlayersScreen())),
      ),
      _NavGridItem(
        title: 'AI Win Predictor',
        subtitle: 'AIML Probability Model',
        icon: Icons.psychology_rounded,
        color: const Color(0xFFFFB300),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiPredictionScreen())),
      ),
      _NavGridItem(
        title: 'Tournaments',
        subtitle: 'Points table & NRR',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFF00E5FF),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TournamentScreen())),
      ),
      _NavGridItem(
        title: 'Statistics',
        subtitle: 'Run & wicket charts',
        icon: Icons.insert_chart_rounded,
        color: const Color(0xFFE040FB),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatisticsScreen())),
      ),
      _NavGridItem(
        title: 'Premium ₹5/mo',
        subtitle: auth.isPremium ? 'Active Pro Member' : 'Advanced Analytics',
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFFFF9100),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: navItems.length,
      itemBuilder: (context, index) {
        final item = navItems[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: item.onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: item.color, size: 24),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                    ),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedMatchCard(BuildContext context, CricketMatch match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MatchResultScreen(match: match)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(match.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('COMPLETED', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(match.innings1?.battingTeamName ?? match.teamA.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    Text('${match.innings1?.totalRuns ?? 0}/${match.innings1?.wickets ?? 0} (${match.innings1?.oversString ?? "0.0"})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(match.innings2?.battingTeamName ?? match.teamB.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    Text('${match.innings2?.totalRuns ?? 0}/${match.innings2?.wickets ?? 0} (${match.innings2?.oversString ?? "0.0"})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      match.resultSummary ?? 'Match Concluded',
                      style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ScorecardScreen(match: match)),
                        );
                      },
                      child: const Text('Scorecard >', style: TextStyle(color: AppColors.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ),
    );
  }
}

class _NavGridItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _NavGridItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

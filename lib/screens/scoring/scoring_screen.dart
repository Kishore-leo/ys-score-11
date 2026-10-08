import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/cricket_match.dart';
import '../../models/team.dart';
import '../../models/innings_data.dart';
import '../../models/ball_record.dart';
import '../../providers/scoring_provider.dart';
import 'scorecard_screen.dart';
import 'match_result_screen.dart';
import 'opening_players_dialog.dart';

class ScoringScreen extends StatefulWidget {
  const ScoringScreen({super.key});

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<ScoringScreen> {
  @override
  Widget build(BuildContext context) {
    final scoring = context.watch<ScoringProvider>();
    final match = scoring.activeMatch;

    if (match == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('SCORING')),
        body: const Center(
          child: Text('No active match found', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    // Check if match completed or innings break
    if (match.status == MatchStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MatchResultScreen(match: match)),
        );
      });
    } else if (match.status == MatchStatus.inningBreak) {
      return _buildInningsBreakView(context, match, scoring);
    }

    final innings = match.currentInnings;
    if (innings == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('SCORING')),
        body: const Center(child: Text('Innings data not ready')),
      );
    }

    final battingTeam = innings.battingTeamId == match.teamA.id ? match.teamA : match.teamB;
    final bowlingTeam = innings.bowlingTeamId == match.teamA.id ? match.teamA : match.teamB;

    final strikerCard = innings.currentStrikerId != null
        ? innings.battingScorecards[innings.currentStrikerId]
        : null;
    final nonStrikerCard = innings.currentNonStrikerId != null
        ? innings.battingScorecards[innings.currentNonStrikerId]
        : null;
    final bowlerCard = innings.currentBowlerId != null
        ? innings.bowlingScorecards[innings.currentBowlerId]
        : null;

    final isInnings2 = match.status == MatchStatus.inning2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(match.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(
              '${match.totalOvers} Overs • ${isInnings2 ? "2nd Innings" : "1st Innings"}',
              style: const TextStyle(fontSize: 11, color: AppColors.accent),
            ),
          ],
        ),
        actions: [
          // Undo Button (prominent)
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: scoring.canUndo ? AppColors.accent : AppColors.textMuted,
            ),
            icon: const Icon(Icons.undo_rounded, size: 20),
            label: const Text('UNDO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            onPressed: scoring.canUndo ? () => scoring.undo() : null,
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_outlined, color: Colors.white),
            tooltip: 'Full Scorecard',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ScorecardScreen(match: match)),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            color: AppColors.cardLight,
            onSelected: (val) {
              if (val == 'end_innings') {
                _confirmEndInnings(context, scoring);
              } else if (val == 'ball_by_ball') {
                _showBallByBallTimeline(context, innings);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'ball_by_ball', child: Text('Ball-by-Ball Commentary')),
              const PopupMenuItem(value: 'end_innings', child: Text('End Current Innings', style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable top match & player cards
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // 1. TOP SCOREBOARD
                  _buildMainScoreboard(match, innings, battingTeam.name, isInnings2),
                  const SizedBox(height: 12),

                  // 2. THIS OVER TIMELINE STRIP
                  _buildThisOverStrip(context, innings),
                  const SizedBox(height: 12),

                  // 3. CURRENT BATSMEN CARD
                  _buildBatsmenSection(context, innings, strikerCard, nonStrikerCard, scoring),
                  const SizedBox(height: 12),

                  // 4. CURRENT BOWLER CARD
                  _buildBowlerSection(context, innings, bowlerCard, bowlingTeam, scoring),
                ],
              ),
            ),
          ),

          // 5. FIXED GROUND-OPTIMIZED LARGE SCORING PAD
          _buildGroundScoringPad(context, scoring, innings, battingTeam, bowlingTeam),
        ],
      ),
    );
  }

  // ==========================================
  // TOP SCOREBOARD
  // ==========================================
  Widget _buildMainScoreboard(CricketMatch match, InningsData innings, String battingTeamName, bool isInnings2) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF162438), Color(0xFF0F1826)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                battingTeamName.toUpperCase(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6)),
                child: Text('CRR: ${innings.currentRunRate.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              RichText(
                text: TextSpan(
                  text: '${innings.totalRuns}',
                  style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.accent, height: 1),
                  children: [
                    TextSpan(
                      text: ' / ${innings.wickets}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${innings.oversString} / ${match.totalOvers}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const Text('OVERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.0)),
                ],
              ),
            ],
          ),
          if (isInnings2 && match.targetRuns != null) ...[
            const Divider(color: AppColors.border, height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target: ${match.targetRuns} | Need ${match.requiredRuns} from ${match.remainingBalls} balls',
                  style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w800, fontSize: 12),
                ),
                Text(
                  'RRR: ${match.requiredRunRate?.toStringAsFixed(2) ?? "-"}',
                  style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // THIS OVER STRIP
  // ==========================================
  Widget _buildThisOverStrip(BuildContext context, InningsData innings) {
    final currentOver = innings.currentOver;
    final balls = currentOver != null ? currentOver.balls : <BallRecord>[];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(
            'THIS OVER ${innings.legalBallsBowled ~/ 6 + 1}:',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 0.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: balls.isEmpty
                ? const Text('Yet to bowl', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: balls.map((b) => _buildBallCircle(b)).toList(),
                    ),
                  ),
          ),
          InkWell(
            onTap: () => _showBallByBallTimeline(context, innings),
            child: const Icon(Icons.history_rounded, size: 20, color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  Widget _buildBallCircle(BallRecord b) {
    Color bg = AppColors.cardLight;
    Color textColor = Colors.white;

    if (b.isWicket) {
      bg = AppColors.danger;
      textColor = Colors.white;
    } else if (b.runsScored == 4) {
      bg = AppColors.cyan.withOpacity(0.3);
      textColor = AppColors.cyan;
    } else if (b.runsScored == 6) {
      bg = AppColors.gold.withOpacity(0.3);
      textColor = AppColors.gold;
    } else if (b.extraType == ExtraType.wide || b.extraType == ExtraType.noBall) {
      bg = AppColors.amber.withOpacity(0.25);
      textColor = AppColors.amber;
    }

    return Container(
      margin: const EdgeInsets.only(right: 6),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(
          b.shortDisplay,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
    );
  }

  // ==========================================
  // BATSMEN SECTION
  // ==========================================
  Widget _buildBatsmenSection(
    BuildContext context,
    InningsData innings,
    BatsmanScorecard? striker,
    BatsmanScorecard? nonStriker,
    ScoringProvider scoring,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('BATSMEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 0.5)),
              const Row(
                children: [
                  SizedBox(width: 35, child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                  SizedBox(width: 35, child: Text('B', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                  SizedBox(width: 35, child: Text('4s', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                  SizedBox(width: 35, child: Text('6s', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                  SizedBox(width: 50, child: Text('SR', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                ],
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 14),
          if (striker != null) _buildBatsmanRow(striker, isStriker: true, onSwap: () => scoring.swapStrike()),
          const SizedBox(height: 6),
          if (nonStriker != null) _buildBatsmanRow(nonStriker, isStriker: false, onSwap: () => scoring.swapStrike()),
        ],
      ),
    );
  }

  Widget _buildBatsmanRow(BatsmanScorecard card, {required bool isStriker, required VoidCallback onSwap}) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              if (isStriker)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
                )
              else
                const SizedBox(width: 14),
              Expanded(
                child: Text(
                  card.playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isStriker ? FontWeight.w900 : FontWeight.w600,
                    color: isStriker ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              if (isStriker)
                const Text('*', style: TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(width: 35, child: Text('${card.runs}', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: isStriker ? AppColors.accent : Colors.white, fontSize: 13))),
        SizedBox(width: 35, child: Text('${card.balls}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        SizedBox(width: 35, child: Text('${card.fours}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        SizedBox(width: 35, child: Text('${card.sixes}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        SizedBox(width: 50, child: Text(card.strikeRate.toStringAsFixed(1), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold))),
      ],
    );
  }

  // ==========================================
  // BOWLER SECTION
  // ==========================================
  Widget _buildBowlerSection(
    BuildContext context,
    InningsData innings,
    BowlerScorecard? bowler,
    Team bowlingTeam,
    ScoringProvider scoring,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CURRENT BOWLER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textMuted, letterSpacing: 0.5)),
              const Row(
                children: [
                  SizedBox(width: 38, child: Text('O', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                  SizedBox(width: 35, child: Text('M', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                  SizedBox(width: 35, child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                  SizedBox(width: 35, child: Text('W', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                  SizedBox(width: 48, child: Text('ECON', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                ],
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 14),
          if (bowler != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    bowler.playerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                  ),
                ),
                SizedBox(width: 38, child: Text(bowler.oversString, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13))),
                SizedBox(width: 35, child: Text('${bowler.maidens}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                SizedBox(width: 35, child: Text('${bowler.runsConceded}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                SizedBox(width: 35, child: Text('${bowler.wickets}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 13))),
                SizedBox(width: 48, child: Text(bowler.economy.toStringAsFixed(2), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            )
          else
            const Text('No bowler assigned', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  // ==========================================
  // GROUND SCORING PAD (ONE-HANDED EASY TOUCH)
  // ==========================================
  Widget _buildGroundScoringPad(
    BuildContext context,
    ScoringProvider scoring,
    InningsData innings,
    Team battingTeam,
    Team bowlingTeam,
  ) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 18),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Fast Action Controls (Swap, Change Bowler, Change Batsman, Over End)
          Row(
            children: [
              _buildControlButton('SWAP STRIKE', Icons.swap_horiz_rounded, AppColors.cyan, () => scoring.swapStrike()),
              const SizedBox(width: 8),
              _buildControlButton('CHANGE BOWLER', Icons.sports_baseball_outlined, AppColors.amber, () => _openChangeBowlerDialog(context, bowlingTeam, scoring)),
              const SizedBox(width: 8),
              _buildControlButton('END OVER', Icons.redo_rounded, AppColors.textSecondary, () => scoring.endOver()),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Large Run Buttons: 0, 1, 2, 3, 4, 6
          Row(
            children: [
              _buildRunButton(0, scoring),
              const SizedBox(width: 6),
              _buildRunButton(1, scoring),
              const SizedBox(width: 6),
              _buildRunButton(2, scoring),
              const SizedBox(width: 6),
              _buildRunButton(3, scoring),
              const SizedBox(width: 6),
              _buildRunButton(4, scoring, isBoundary: true),
              const SizedBox(width: 6),
              _buildRunButton(6, scoring, isBoundary: true),
            ],
          ),
          const SizedBox(height: 10),

          // Row 3: Extras and Wicket Buttons
          Row(
            children: [
              _buildExtraButton('WD', ExtraType.wide, scoring),
              const SizedBox(width: 6),
              _buildExtraButton('NB', ExtraType.noBall, scoring),
              const SizedBox(width: 6),
              _buildExtraButton('BYE', ExtraType.bye, scoring),
              const SizedBox(width: 6),
              _buildExtraButton('LB', ExtraType.legBye, scoring),
              const SizedBox(width: 8),
              // Prominent Wicket Button
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _openWicketModal(context, innings, battingTeam, bowlingTeam, scoring),
                    child: const Text('WICKET', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRunButton(int runs, ScoringProvider scoring, {bool isBoundary = false}) {
    Color btnColor = AppColors.card;
    Color textColor = Colors.white;

    if (runs == 4) {
      btnColor = const Color(0xFF0F3642);
      textColor = AppColors.cyan;
    } else if (runs == 6) {
      btnColor = const Color(0xFF3F2B07);
      textColor = AppColors.gold;
    } else if (runs == 0) {
      btnColor = AppColors.card;
      textColor = AppColors.textSecondary;
    }

    return Expanded(
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            foregroundColor: textColor,
            padding: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isBoundary ? textColor.withOpacity(0.5) : AppColors.border),
            ),
          ),
          onPressed: () => scoring.scoreBall(runs),
          child: Text(
            '$runs',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildExtraButton(String label, ExtraType type, ScoringProvider scoring) {
    return Expanded(
      flex: 1,
      child: SizedBox(
        height: 48,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: const BorderSide(color: AppColors.border, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _showExtraDialog(context, type, scoring),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
        ),
      ),
    );
  }

  Widget _buildControlButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: SizedBox(
        height: 36,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: Icon(icon, size: 14, color: color),
          label: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
          onPressed: onTap,
        ),
      ),
    );
  }

  // ==========================================
  // DIALOGS & MODALS
  // ==========================================

  void _showExtraDialog(BuildContext context, ExtraType type, ScoringProvider scoring) {
    int extraRuns = 1;
    int batRuns = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            'Score ${type.name.toUpperCase()}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (type == ExtraType.noBall) ...[
                const Text('Runs scored off the bat:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [0, 1, 2, 3, 4, 6].map((r) {
                    final isSel = batRuns == r;
                    return ChoiceChip(
                      label: Text('$r'),
                      selected: isSel,
                      selectedColor: AppColors.accent,
                      onSelected: (_) => setModalState(() => batRuns = r),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              const Text('Extra runs added:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [1, 2, 3, 4, 5].map((e) {
                  final isSel = extraRuns == e;
                  return ChoiceChip(
                    label: Text('$e'),
                    selected: isSel,
                    selectedColor: AppColors.amber,
                    onSelected: (_) => setModalState(() => extraRuns = e),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                scoring.scoreExtra(type: type, extraRuns: extraRuns, batRuns: batRuns);
              },
              child: const Text('Record Extra'),
            ),
          ],
        ),
      ),
    );
  }

  void _openWicketModal(
    BuildContext context,
    InningsData innings,
    Team battingTeam,
    Team bowlingTeam,
    ScoringProvider scoring,
  ) {
    WicketType selectedWicketType = WicketType.bowled;
    String dismissedPlayerId = innings.currentStrikerId ?? '';
    String? fielderId;
    String? nextBatsmanId;

    // Remaining un-batted batsmen
    final unbatted = battingTeam.players.where((p) {
      final card = innings.battingScorecards[p.id];
      final isCurrentlyBatting = p.id == innings.currentStrikerId || p.id == innings.currentNonStrikerId;
      return card == null && !isCurrentlyBatting;
    }).toList();

    if (unbatted.isNotEmpty) {
      nextBatsmanId = unbatted.first.id;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Row(
            children: [
              Icon(Icons.sports_cricket_rounded, color: AppColors.danger),
              SizedBox(width: 8),
              Text('DISMISSAL DETAILS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dismissal Type
                const Text('Dismissal Type', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<WicketType>(
                  value: selectedWicketType,
                  dropdownColor: AppColors.cardLight,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  items: WicketType.values.map((w) {
                    return DropdownMenuItem(value: w, child: Text(w.name.toUpperCase()));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedWicketType = val);
                  },
                ),
                const SizedBox(height: 14),

                // Batsman Dismissed
                const Text('Batsman Dismissed', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: dismissedPlayerId,
                  dropdownColor: AppColors.cardLight,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  items: [
                    if (innings.currentStrikerId != null)
                      DropdownMenuItem(
                        value: innings.currentStrikerId,
                        child: Text('${innings.battingScorecards[innings.currentStrikerId]?.playerName ?? "Striker"} (Striker)'),
                      ),
                    if (innings.currentNonStrikerId != null)
                      DropdownMenuItem(
                        value: innings.currentNonStrikerId,
                        child: Text('${innings.battingScorecards[innings.currentNonStrikerId]?.playerName ?? "Non-Striker"} (Non-Striker)'),
                      ),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => dismissedPlayerId = val);
                  },
                ),
                const SizedBox(height: 14),

                // Fielder selector (if caught, run out, stumped)
                if (selectedWicketType == WicketType.caught ||
                    selectedWicketType == WicketType.runOut ||
                    selectedWicketType == WicketType.stumped) ...[
                  const Text('Fielder Involved', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    value: fielderId,
                    dropdownColor: AppColors.cardLight,
                    style: const TextStyle(color: Colors.white),
                    hint: const Text('Select fielder', style: TextStyle(color: AppColors.textMuted)),
                    items: bowlingTeam.players.map((p) {
                      return DropdownMenuItem<String?>(
                        value: p.id,
                        child: Text('${p.name} (#${p.jerseyNumber})'),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => fielderId = val),
                  ),
                  const SizedBox(height: 14),
                ],

                // Next Batsman (if available)
                if (unbatted.isNotEmpty) ...[
                  const Text('Incoming Batsman', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    value: nextBatsmanId,
                    dropdownColor: AppColors.cardLight,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    items: unbatted.map((p) {
                      return DropdownMenuItem<String?>(
                        value: p.id,
                        child: Text('${p.name} (#${p.jerseyNumber} • ${p.roleDisplayName})'),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => nextBatsmanId = val),
                  ),
                ] else ...[
                  const Text('All Out or No un-batted players left.', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                scoring.scoreWicket(
                  wicketType: selectedWicketType,
                  dismissedPlayerId: dismissedPlayerId,
                  fielderId: fielderId,
                  nextBatsmanId: nextBatsmanId,
                );
              },
              child: const Text('CONFIRM WICKET'),
            ),
          ],
        ),
      ),
    );
  }

  void _openChangeBowlerDialog(BuildContext context, Team bowlingTeam, ScoringProvider scoring) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Select New Bowler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: bowlingTeam.players.length,
            itemBuilder: (context, idx) {
              final player = bowlingTeam.players[idx];
              final isCurrent = player.id == scoring.activeMatch?.currentInnings?.currentBowlerId;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCurrent ? AppColors.accent : AppColors.cardLight,
                  child: Text('#${player.jerseyNumber}', style: TextStyle(color: isCurrent ? Colors.black : Colors.white, fontSize: 12)),
                ),
                title: Text(player.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('${player.roleDisplayName} • ${player.bowlingStyleDisplayName}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  scoring.changeBowler(player.id);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showBallByBallTimeline(BuildContext context, InningsData innings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ball-by-Ball Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 14),
            Expanded(
              child: innings.ballHistory.isEmpty
                  ? const Center(child: Text('No balls bowled yet.', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.builder(
                      itemCount: innings.ballHistory.length,
                      itemBuilder: (context, index) {
                        final ball = innings.ballHistory.reversed.toList()[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              _buildBallCircle(ball),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(ball.commentary, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmEndInnings(BuildContext context, ScoringProvider scoring) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('End Innings?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to end the current innings?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              scoring.endInningsManually();
            },
            child: const Text('End Innings'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INNINGS BREAK SCREEN
  // ==========================================
  Widget _buildInningsBreakView(BuildContext context, CricketMatch match, ScoringProvider scoring) {
    final inn1 = match.innings1!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('INNINGS BREAK')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.coffee_rounded, size: 54, color: AppColors.accent),
              const SizedBox(height: 16),
              const Text('INNINGS 1 CONCLUDED', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                '${inn1.battingTeamName} scored ${inn1.totalRuns} / ${inn1.wickets} in ${inn1.oversString} overs',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    const Text('TARGET FOR INNINGS 2', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${match.targetRuns} RUNS', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.accent)),
                    Text('in ${match.totalOvers} overs (RRR: ${(match.targetRuns! / match.totalOvers).toStringAsFixed(2)})', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => OpeningPlayersDialog(
                        match: match,
                        isSecondInnings: true,
                        onConfirmed: () => setState(() {}),
                      ),
                    );
                  },
                  child: const Text('START 2ND INNINGS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ScorecardScreen(match: match)),
                  );
                },
                child: const Text('VIEW 1ST INNINGS SCORECARD'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

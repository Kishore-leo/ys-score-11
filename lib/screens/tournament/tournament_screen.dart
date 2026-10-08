import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/tournament.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/teams_provider.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  @override
  Widget build(BuildContext context) {
    final tourneyProvider = context.watch<TournamentProvider>();
    final tourneys = tourneyProvider.tournaments;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('TOURNAMENTS & SERIES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.accent, size: 28),
            onPressed: () => _openCreateTournamentDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.emoji_events_rounded),
        label: const Text('NEW TOURNAMENT', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openCreateTournamentDialog(context),
      ),
      body: tourneys.isEmpty
          ? const Center(child: Text('No tournaments created yet.', style: TextStyle(color: AppColors.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tourneys.length,
              itemBuilder: (context, index) {
                final t = tourneys[index];
                return _buildTournamentCard(t);
              },
            ),
    );
  }

  Widget _buildTournamentCard(Tournament t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tournament Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                      Text('${t.location} • ${t.teamIds.length} Teams', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),

          // Points Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: const [
                Expanded(flex: 4, child: Text('TEAM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                Expanded(flex: 1, child: Text('P', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                Expanded(flex: 1, child: Text('W', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                Expanded(flex: 1, child: Text('L', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                Expanded(flex: 1, child: Text('PTS', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.accent))),
                Expanded(flex: 2, child: Text('NRR', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.cyan))),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),

          // Points Table Rows
          ...t.pointsTable.asMap().entries.map((entry) {
            final idx = entry.key;
            final row = entry.value;
            final isLeader = idx == 0;

            return Container(
              color: isLeader ? AppColors.accent.withOpacity(0.04) : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        Text('${idx + 1}. ', style: TextStyle(fontWeight: FontWeight.bold, color: isLeader ? AppColors.accent : AppColors.textMuted, fontSize: 12)),
                        Expanded(
                          child: Text(
                            row.teamName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: isLeader ? FontWeight.w900 : FontWeight.bold, color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(flex: 1, child: Text('${row.played}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12))),
                  Expanded(flex: 1, child: Text('${row.won}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 1, child: Text('${row.lost}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger, fontSize: 12))),
                  Expanded(flex: 1, child: Text('${row.points}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.accent, fontSize: 13))),
                  Expanded(flex: 2, child: Text(row.nrrString, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold, fontSize: 11))),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _openCreateTournamentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'Young Storms Arena');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Create Tournament', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Tournament Name (e.g. Young Storms Cup)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: locationCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Location / Venue'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                final teams = context.read<TeamsProvider>().teams;
                await context.read<TournamentProvider>().createTournament(
                  name: nameCtrl.text.trim(),
                  location: locationCtrl.text.trim(),
                  startDate: DateTime.now(),
                  endDate: DateTime.now().add(const Duration(days: 14)),
                  teams: teams,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/team.dart';
import '../../models/player.dart';
import '../../providers/teams_provider.dart';
import '../players/player_profile_screen.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teamsProvider = context.watch<TeamsProvider>();
    final teams = teamsProvider.teams;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MY TEAMS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.accent, size: 28),
            onPressed: () => _openCreateTeamDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('ADD TEAM', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openCreateTeamDialog(context),
      ),
      body: teams.isEmpty
          ? const Center(child: Text('No teams created yet.', style: TextStyle(color: AppColors.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                return _buildTeamCard(context, team);
              },
            ),
    );
  }

  Widget _buildTeamCard(BuildContext context, Team team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.surface,
          child: Text(
            team.shortName.isNotEmpty ? team.shortName.substring(0, team.shortName.length > 2 ? 2 : team.shortName.length) : 'T',
            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.accent),
          ),
        ),
        title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
        subtitle: Text(
          '${team.players.length} Players • Cap: ${team.captain?.name ?? "None"}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        children: [
          const Divider(color: AppColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Squad Roster', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  icon: const Icon(Icons.person_add_rounded, size: 16, color: AppColors.accent),
                  label: const Text('+ Add Player', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                  onPressed: () => _openAddPlayerDialog(context, team),
                ),
              ],
            ),
          ),
          ...team.players.map((p) {
            return ListTile(
              dense: true,
              leading: Text('#${p.jerseyNumber}', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('${p.roleDisplayName} • ${p.battingStyleDisplayName}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PlayerProfileScreen(player: p, teamName: team.name)),
                );
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _openCreateTeamDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final shortNameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Create New Team', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Team Name (e.g. Young Storms)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: shortNameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Short Name (e.g. YS)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                await context.read<TeamsProvider>().createTeam(
                  name: nameCtrl.text.trim(),
                  shortName: shortNameCtrl.text.trim().isNotEmpty ? shortNameCtrl.text.trim() : 'TEAM',
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

  void _openAddPlayerDialog(BuildContext context, Team team) {
    final nameCtrl = TextEditingController();
    final jerseyCtrl = TextEditingController(text: '${team.players.length + 1}');
    PlayerRole role = PlayerRole.batsman;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text('Add Player to ${team.name}', style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Player Name'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: jerseyCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Jersey Number'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<PlayerRole>(
                value: role,
                dropdownColor: AppColors.cardLight,
                style: const TextStyle(color: Colors.white),
                items: PlayerRole.values.map((r) {
                  return DropdownMenuItem(value: r, child: Text(r.name.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => role = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  final player = Player(
                    id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    jerseyNumber: int.tryParse(jerseyCtrl.text) ?? (team.players.length + 1),
                    role: role,
                  );
                  await context.read<TeamsProvider>().addPlayerToTeam(team.id, player);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Add Player'),
            ),
          ],
        ),
      ),
    );
  }
}

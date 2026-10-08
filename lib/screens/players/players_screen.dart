import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/player.dart';
import '../../providers/teams_provider.dart';
import 'player_profile_screen.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _searchController = TextEditingController();
  PlayerRole? _selectedRoleFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamsProvider = context.watch<TeamsProvider>();
    final query = _searchController.text.toLowerCase().trim();

    // Gather all players with team association
    final allPlayersWithTeam = <MapEntry<Player, String>>[];
    for (final team in teamsProvider.teams) {
      for (final player in team.players) {
        allPlayersWithTeam.add(MapEntry(player, team.name));
      }
    }

    final filtered = allPlayersWithTeam.where((entry) {
      final p = entry.key;
      final matchesQuery = p.name.toLowerCase().contains(query) || entry.value.toLowerCase().contains(query);
      final matchesRole = _selectedRoleFilter == null || p.role == _selectedRoleFilter;
      return matchesQuery && matchesRole;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PLAYER DIRECTORY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
      ),
      body: Column(
        children: [
          // Search & Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search player or team...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Roles', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('Batsmen', PlayerRole.batsman),
                      const SizedBox(width: 8),
                      _buildFilterChip('Bowlers', PlayerRole.bowler),
                      const SizedBox(width: 8),
                      _buildFilterChip('All-Rounders', PlayerRole.allRounder),
                      const SizedBox(width: 8),
                      _buildFilterChip('Wicketkeepers', PlayerRole.wicketKeeper),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Players List
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No matching players found', style: TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final player = item.key;
                      final teamName = item.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.surface,
                            child: Text(
                              '#${player.jerseyNumber}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 13),
                            ),
                          ),
                          title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          subtitle: Text(
                            '$teamName • ${player.roleDisplayName}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${player.stats.runs} Runs', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('${player.stats.wickets} Wkts', style: const TextStyle(color: AppColors.cyan, fontSize: 11)),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PlayerProfileScreen(player: player, teamName: teamName)),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, PlayerRole? role) {
    final isSelected = _selectedRoleFilter == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRoleFilter = role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withOpacity(0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.accent : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

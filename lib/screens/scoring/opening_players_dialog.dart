import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/cricket_match.dart';
import '../../models/team.dart';
import '../../models/player.dart';
import '../../providers/scoring_provider.dart';

class OpeningPlayersDialog extends StatefulWidget {
  final CricketMatch match;
  final bool isSecondInnings;
  final VoidCallback onConfirmed;

  const OpeningPlayersDialog({
    super.key,
    required this.match,
    this.isSecondInnings = false,
    required this.onConfirmed,
  });

  @override
  State<OpeningPlayersDialog> createState() => _OpeningPlayersDialogState();
}

class _OpeningPlayersDialogState extends State<OpeningPlayersDialog> {
  String? _strikerId;
  String? _nonStrikerId;
  String? _bowlerId;

  late Team _battingTeam;
  late Team _bowlingTeam;

  @override
  void initState() {
    super.initState();
    if (widget.isSecondInnings) {
      _battingTeam = widget.match.bowlingFirstTeam!;
      _bowlingTeam = widget.match.battingFirstTeam!;
    } else {
      _battingTeam = widget.match.battingFirstTeam!;
      _bowlingTeam = widget.match.bowlingFirstTeam!;
    }

    if (_battingTeam.players.length >= 2) {
      _strikerId = _battingTeam.players[0].id;
      _nonStrikerId = _battingTeam.players[1].id;
    }
    if (_bowlingTeam.players.isNotEmpty) {
      // Pick first bowler or last player
      final bowlers = _bowlingTeam.players.where((p) => p.role == PlayerRole.bowler || p.role == PlayerRole.allRounder).toList();
      _bowlerId = bowlers.isNotEmpty ? bowlers.first.id : _bowlingTeam.players.last.id;
    }
  }

  void _confirm() async {
    if (_strikerId == null || _nonStrikerId == null || _bowlerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select striker, non-striker, and opening bowler.')),
      );
      return;
    }
    if (_strikerId == _nonStrikerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Striker and non-striker must be different players.')),
      );
      return;
    }

    final scoring = context.read<ScoringProvider>();
    if (widget.isSecondInnings) {
      await scoring.startSecondInnings(
        strikerId: _strikerId!,
        nonStrikerId: _nonStrikerId!,
        bowlerId: _bowlerId!,
      );
    } else {
      await scoring.setOpeningPlayers(
        strikerId: _strikerId!,
        nonStrikerId: _nonStrikerId!,
        bowlerId: _bowlerId!,
      );
    }

    widget.onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sports_cricket_rounded, color: AppColors.accent, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    widget.isSecondInnings ? 'START 2ND INNINGS' : 'SELECT OPENING PLAYERS',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Select opening batsmen for ${_battingTeam.name} and bowler for ${_bowlingTeam.name}.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // Striker
              const Text('Opening Batsman (Striker)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
              const SizedBox(height: 6),
              _buildPlayerDropdown(_battingTeam.players, _strikerId, (val) => setState(() => _strikerId = val)),
              const SizedBox(height: 16),

              // Non-Striker
              const Text('Opening Batsman (Non-Striker)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cyan)),
              const SizedBox(height: 6),
              _buildPlayerDropdown(_battingTeam.players, _nonStrikerId, (val) => setState(() => _nonStrikerId = val)),
              const SizedBox(height: 16),

              // Opening Bowler
              const Text('Opening Bowler', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.amber)),
              const SizedBox(height: 6),
              _buildPlayerDropdown(_bowlingTeam.players, _bowlerId, (val) => setState(() => _bowlerId = val)),
              const SizedBox(height: 24),

              // Start Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _confirm,
                  child: const Text('START SCORING BALL 1', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerDropdown(List<Player> players, String? selectedId, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedId,
      dropdownColor: AppColors.cardLight,
      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
      items: players.map((p) {
        return DropdownMenuItem<String>(
          value: p.id,
          child: Text('${p.name} (#${p.jerseyNumber} • ${p.roleDisplayName})'),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

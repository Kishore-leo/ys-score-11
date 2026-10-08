import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/cricket_match.dart';
import '../../models/team.dart';
import '../../models/player.dart';
import '../../providers/teams_provider.dart';
import '../../providers/scoring_provider.dart';
import '../scoring/scoring_screen.dart';
import '../scoring/opening_players_dialog.dart';

class CreateMatchWizard extends StatefulWidget {
  const CreateMatchWizard({super.key});

  @override
  State<CreateMatchWizard> createState() => _CreateMatchWizardState();
}

class _CreateMatchWizardState extends State<CreateMatchWizard> {
  int _currentStep = 0;

  // Step 1: Match Details
  final _matchNameController = TextEditingController(text: 'Ground Match 1');
  MatchType _selectedMatchType = MatchType.t20;
  final _oversController = TextEditingController(text: '20');
  final _venueController = TextEditingController(text: 'City Cricket Ground');
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '10:00 AM';

  // Step 2: Team Selection
  Team? _teamA;
  Team? _teamB;

  // Step 3: Squad Selection (Player IDs selected for Playing XI)
  final Set<String> _selectedTeamAPlayerIds = {};
  final Set<String> _selectedTeamBPlayerIds = {};

  // Step 4: Toss
  String? _tossWinnerId;
  TossDecision _tossDecision = TossDecision.bat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final teamsProvider = context.read<TeamsProvider>();
      if (teamsProvider.teams.length >= 2) {
        setState(() {
          _teamA = teamsProvider.teams[0];
          _teamB = teamsProvider.teams[1];
          _initSquads();
        });
      }
    });
  }

  void _initSquads() {
    if (_teamA != null) {
      _selectedTeamAPlayerIds.clear();
      _selectedTeamAPlayerIds.addAll(_teamA!.players.take(11).map((p) => p.id));
    }
    if (_teamB != null) {
      _selectedTeamBPlayerIds.clear();
      _selectedTeamBPlayerIds.addAll(_teamB!.players.take(11).map((p) => p.id));
    }
    _tossWinnerId = _teamA?.id;
  }

  @override
  void dispose() {
    _matchNameController.dispose();
    _oversController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  // ==========================================
  // WIZARD NAVIGATION
  // ==========================================

  void _nextStep() {
    if (_currentStep == 0) {
      if (_matchNameController.text.trim().isEmpty) {
        _showSnackBar('Please enter a match name');
        return;
      }
      final overs = int.tryParse(_oversController.text);
      if (overs == null || overs <= 0) {
        _showSnackBar('Please enter valid number of overs');
        return;
      }
    } else if (_currentStep == 1) {
      if (_teamA == null || _teamB == null) {
        _showSnackBar('Please select both Team A and Team B');
        return;
      }
      if (_teamA!.id == _teamB!.id) {
        _showSnackBar('Team A and Team B must be different teams');
        return;
      }
      _initSquads();
    } else if (_currentStep == 2) {
      if (_selectedTeamAPlayerIds.length < 2 || _selectedTeamBPlayerIds.length < 2) {
        _showSnackBar('Please select at least 2 players for each team squad');
        return;
      }
    } else if (_currentStep == 3) {
      if (_tossWinnerId == null) {
        _showSnackBar('Please select toss winner');
        return;
      }
    }

    if (_currentStep < 4) {
      setState(() => _currentStep += 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Start the match and launch opening players dialog
  void _startMatch() async {
    final scoringProvider = context.read<ScoringProvider>();
    final overs = int.parse(_oversController.text);

    // Create active match
    final filteredTeamA = _teamA!.copyWith(
      players: _teamA!.players.where((p) => _selectedTeamAPlayerIds.contains(p.id)).toList(),
    );
    final filteredTeamB = _teamB!.copyWith(
      players: _teamB!.players.where((p) => _selectedTeamBPlayerIds.contains(p.id)).toList(),
    );

    final match = await scoringProvider.createMatch(
      name: _matchNameController.text.trim(),
      teamA: filteredTeamA,
      teamB: filteredTeamB,
      totalOvers: overs,
      matchType: _selectedMatchType,
      venue: _venueController.text.trim(),
      matchDate: _selectedDate,
      startTime: _selectedTime,
    );

    await scoringProvider.setToss(
      matchId: match.id,
      tossWinnerId: _tossWinnerId!,
      tossDecision: _tossDecision,
    );

    if (mounted) {
      // Show Opening Players Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => OpeningPlayersDialog(
          match: match,
          onConfirmed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ScoringScreen()),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('CREATE MATCH - STEP ${_currentStep + 1}/5'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Step Progress Bar
          _buildStepProgressBar(),

          // Step Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildCurrentStepContent(),
            ),
          ),

          // Bottom Step Actions
          _buildBottomActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStepProgressBar() {
    final stepTitles = ['Details', 'Teams', 'Players', 'Toss', 'Confirm'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent
                      ? AppColors.accent
                      : (isCompleted ? AppColors.accent.withOpacity(0.3) : AppColors.card),
                  border: Border.all(
                    color: isCurrent || isCompleted ? AppColors.accent : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, size: 16, color: AppColors.accent)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCurrent ? Colors.black : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stepTitles[index],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? AppColors.accent : AppColors.textMuted,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1MatchDetails();
      case 1:
        return _buildStep2TeamSelection();
      case 2:
        return _buildStep3PlayerSelection();
      case 3:
        return _buildStep4Toss();
      case 4:
        return _buildStep5Confirmation();
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================
  // STEP 1: MATCH DETAILS
  // ==========================================
  Widget _buildStep1MatchDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Match Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 6),
        const Text('Configure match format, overs, and ground location.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 20),

        // Match Name
        const Text('Match Name / Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _matchNameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'e.g. Young Storms Cup Match 1'),
        ),
        const SizedBox(height: 18),

        // Match Type
        const Text('Match Format', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTypeChip('T10', MatchType.t10, '10'),
            const SizedBox(width: 8),
            _buildTypeChip('T20', MatchType.t20, '20'),
            const SizedBox(width: 8),
            _buildTypeChip('ODI (50)', MatchType.odi, '50'),
            const SizedBox(width: 8),
            _buildTypeChip('Custom', MatchType.custom, _oversController.text),
          ],
        ),
        const SizedBox(height: 18),

        // Number of Overs
        const Text('Number of Overs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _oversController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter total overs per innings',
            suffixText: 'Overs',
            suffixStyle: TextStyle(color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 18),

        // Venue
        const Text('Ground / Venue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _venueController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. Young Storms Arena Ground',
            prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 18),

        // Date & Time
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Start Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() => _selectedTime = time.format(context));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Text(_selectedTime, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(String label, MatchType type, String oversVal) {
    final isSelected = _selectedMatchType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMatchType = type;
            _oversController.text = oversVal;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent.withOpacity(0.2) : AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppColors.accent : AppColors.border, width: 1.5),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STEP 2: TEAM SELECTION
  // ==========================================
  Widget _buildStep2TeamSelection() {
    final teamsProvider = context.watch<TeamsProvider>();
    final allTeams = teamsProvider.teams;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Teams', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 4),
                Text('Choose or create Team A and Team B', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.accent),
              label: const Text('NEW TEAM', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () => _openCreateTeamDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Team A Picker Card
        _buildTeamSelectorCard(
          title: 'TEAM A (Host / Team 1)',
          selectedTeam: _teamA,
          allTeams: allTeams,
          onSelected: (team) => setState(() => _teamA = team),
        ),
        const SizedBox(height: 18),

        // VS Divider
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text('VS', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 18),

        // Team B Picker Card
        _buildTeamSelectorCard(
          title: 'TEAM B (Visitor / Team 2)',
          selectedTeam: _teamB,
          allTeams: allTeams,
          onSelected: (team) => setState(() => _teamB = team),
        ),
      ],
    );
  }

  Widget _buildTeamSelectorCard({
    required String title,
    required Team? selectedTeam,
    required List<Team> allTeams,
    required ValueChanged<Team> onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          DropdownButtonFormField<Team>(
            value: selectedTeam,
            dropdownColor: AppColors.cardLight,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.shield_outlined, color: AppColors.accent),
            ),
            items: allTeams.map((t) {
              return DropdownMenuItem<Team>(
                value: t,
                child: Text('${t.name} (${t.players.length} players)'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) onSelected(val);
            },
          ),
          if (selectedTeam != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                const SizedBox(width: 4),
                Text(
                  'Captain: ${selectedTeam.captain?.name ?? "Not assigned"}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // STEP 3: PLAYER SELECTION
  // ==========================================
  Widget _buildStep3PlayerSelection() {
    if (_teamA == null || _teamB == null) return const SizedBox.shrink();

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Playing Squad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Choose players who will bat and bowl in this match.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 14),

          // Team Tabs
          TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: '${_teamA!.name} (${_selectedTeamAPlayerIds.length})'),
              Tab(text: '${_teamB!.name} (${_selectedTeamBPlayerIds.length})'),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 440,
            child: TabBarView(
              children: [
                _buildSquadList(_teamA!, _selectedTeamAPlayerIds),
                _buildSquadList(_teamB!, _selectedTeamBPlayerIds),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquadList(Team team, Set<String> selectedIds) {
    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${selectedIds.length} players selected', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            TextButton.icon(
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: AppColors.accent),
              label: const Text('+ Add Player', style: TextStyle(color: AppColors.accent, fontSize: 12)),
              onPressed: () => _openCreatePlayerDialog(team),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...team.players.map((player) {
          final isSelected = selectedIds.contains(player.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent.withOpacity(0.12) : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.accent.withOpacity(0.5) : AppColors.border,
              ),
            ),
            child: CheckboxListTile(
              activeColor: AppColors.accent,
              checkColor: Colors.black,
              value: isSelected,
              onChanged: (bool? val) {
                setState(() {
                  if (val == true) {
                    selectedIds.add(player.id);
                  } else {
                    selectedIds.remove(player.id);
                  }
                });
              },
              title: Row(
                children: [
                  Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  if (player.id == team.captainId) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(4)),
                      child: const Text('C', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  if (player.id == team.viceCaptainId) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.cyan, borderRadius: BorderRadius.circular(4)),
                      child: const Text('VC', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                '#${player.jerseyNumber} • ${player.roleDisplayName} • ${player.battingStyleDisplayName}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // STEP 4: TOSS
  // ==========================================
  Widget _buildStep4Toss() {
    if (_teamA == null || _teamB == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Match Toss', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        const Text('Who won the toss and what did they choose to do?', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 24),

        // Who won toss?
        const Text('Toss Winner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tossWinnerId = _teamA!.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _tossWinnerId == _teamA!.id ? AppColors.accent.withOpacity(0.18) : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _tossWinnerId == _teamA!.id ? AppColors.accent : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.military_tech_rounded, color: _tossWinnerId == _teamA!.id ? AppColors.accent : AppColors.textMuted, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        _teamA!.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _tossWinnerId == _teamA!.id ? AppColors.accent : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tossWinnerId = _teamB!.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _tossWinnerId == _teamB!.id ? AppColors.accent.withOpacity(0.18) : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _tossWinnerId == _teamB!.id ? AppColors.accent : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.military_tech_rounded, color: _tossWinnerId == _teamB!.id ? AppColors.accent : AppColors.textMuted, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        _teamB!.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _tossWinnerId == _teamB!.id ? AppColors.accent : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Elected to Bat or Bowl
        const Text('Elected To', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tossDecision = TossDecision.bat),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _tossDecision == TossDecision.bat ? AppColors.cyan.withOpacity(0.18) : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _tossDecision == TossDecision.bat ? AppColors.cyan : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.sports_cricket_rounded, color: _tossDecision == TossDecision.bat ? AppColors.cyan : AppColors.textMuted, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        'BAT FIRST',
                        style: TextStyle(
                          color: _tossDecision == TossDecision.bat ? AppColors.cyan : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tossDecision = TossDecision.bowl),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _tossDecision == TossDecision.bowl ? AppColors.amber.withOpacity(0.18) : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _tossDecision == TossDecision.bowl ? AppColors.amber : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.sports_baseball_rounded, color: _tossDecision == TossDecision.bowl ? AppColors.amber : AppColors.textMuted, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        'BOWL FIRST',
                        style: TextStyle(
                          color: _tossDecision == TossDecision.bowl ? AppColors.amber : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // STEP 5: MATCH CONFIRMATION
  // ==========================================
  Widget _buildStep5Confirmation() {
    final winnerTeam = _tossWinnerId == _teamA!.id ? _teamA! : _teamB!;
    final otherTeam = _tossWinnerId == _teamA!.id ? _teamB! : _teamA!;
    final battingFirstTeam = _tossDecision == TossDecision.bat ? winnerTeam : otherTeam;
    final bowlingFirstTeam = _tossDecision == TossDecision.bat ? otherTeam : winnerTeam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Match Confirmation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        const Text('Review match configuration before starting ball 1.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Match Name', _matchNameController.text),
              const Divider(color: AppColors.border, height: 20),
              _buildSummaryRow('Format & Overs', '${_selectedMatchType.name.toUpperCase()} • ${_oversController.text} Overs'),
              const Divider(color: AppColors.border, height: 20),
              _buildSummaryRow('Teams', '${_teamA!.name} vs ${_teamB!.name}'),
              const Divider(color: AppColors.border, height: 20),
              _buildSummaryRow('Venue', _venueController.text.isNotEmpty ? _venueController.text : 'Neutral Ground'),
              const Divider(color: AppColors.border, height: 20),
              _buildSummaryRow('Date & Time', '${DateFormat("dd MMM yyyy").format(_selectedDate)} at $_selectedTime'),
              const Divider(color: AppColors.border, height: 20),
              _buildSummaryRow('Toss Result', '${winnerTeam.name} won and elected to ${_tossDecision.name}'),
              const Divider(color: AppColors.border, height: 20),
              _buildSummaryRow('Batting First', battingFirstTeam.name, highlight: true),
              const Divider(color: AppColors.border, height: 20),
              _buildSummaryRow('Bowling First', bowlingFirstTeam.name),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppColors.accent : Colors.white,
            fontWeight: highlight ? FontWeight.w900 : FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionButtons() {
    final isLastStep = _currentStep == 4;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('BACK'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastStep ? AppColors.accent : AppColors.accent,
                foregroundColor: Colors.black,
              ),
              onPressed: isLastStep ? _startMatch : _nextStep,
              child: Text(isLastStep ? 'START MATCH' : 'CONTINUE'),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INLINE TEAM & PLAYER CREATION DIALOGS
  // ==========================================

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
                final newTeam = await context.read<TeamsProvider>().createTeam(
                  name: nameCtrl.text.trim(),
                  shortName: shortNameCtrl.text.trim().isNotEmpty ? shortNameCtrl.text.trim() : 'TEAM',
                );
                setState(() => _teamB = newTeam);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openCreatePlayerDialog(Team team) {
    final nameCtrl = TextEditingController();
    final jerseyCtrl = TextEditingController(text: '${team.players.length + 1}');
    PlayerRole selectedRole = PlayerRole.batsman;

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
                value: selectedRole,
                dropdownColor: AppColors.cardLight,
                style: const TextStyle(color: Colors.white),
                items: PlayerRole.values.map((r) {
                  return DropdownMenuItem(value: r, child: Text(r.name.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedRole = val);
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
                    role: selectedRole,
                  );
                  await context.read<TeamsProvider>().addPlayerToTeam(team.id, player);
                  setState(() {
                    if (team.id == _teamA?.id) {
                      _selectedTeamAPlayerIds.add(player.id);
                    } else if (team.id == _teamB?.id) {
                      _selectedTeamBPlayerIds.add(player.id);
                    }
                  });
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

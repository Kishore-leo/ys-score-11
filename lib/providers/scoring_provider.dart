import 'package:flutter/foundation.dart';
import '../models/cricket_match.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../models/innings_data.dart';
import '../models/ball_record.dart';
import '../models/over_record.dart';
import '../services/storage_service.dart';
import '../services/mock_data_service.dart';

class ScoringProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<CricketMatch> _matches = [];
  CricketMatch? _activeMatch;
  bool _isLoading = false;

  // Snapshot undo stack for 100% loss-free state restoration
  final List<CricketMatch> _undoStack = [];

  List<CricketMatch> get matches => _matches;
  CricketMatch? get activeMatch => _activeMatch;
  bool get isLoading => _isLoading;
  bool get canUndo => _undoStack.isNotEmpty;

  List<CricketMatch> get liveMatches => _matches
      .where((m) =>
          m.status == MatchStatus.inning1 ||
          m.status == MatchStatus.inning2 ||
          m.status == MatchStatus.inningBreak)
      .toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<CricketMatch> get completedMatches => _matches
      .where((m) => m.status == MatchStatus.completed)
      .toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<CricketMatch> get upcomingMatches => _matches
      .where((m) => m.status == MatchStatus.setup || m.status == MatchStatus.toss)
      .toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Future<void> init(List<Team> teams) async {
    _isLoading = true;
    notifyListeners();
    var loaded = await _storage.loadMatches();
    if (loaded.isEmpty) {
      loaded = MockDataService.getInitialMatches(teams);
      await _storage.saveMatches(loaded);
    }
    _matches = loaded;

    final activeId = await _storage.getActiveMatchId();
    if (activeId != null) {
      _activeMatch = _matches.cast<CricketMatch?>().firstWhere(
            (m) => m?.id == activeId,
            orElse: () => null,
          );
    }
    _isLoading = false;
    notifyListeners();
  }

  void setActiveMatch(CricketMatch match) {
    _activeMatch = match;
    _undoStack.clear();
    _storage.setActiveMatchId(match.id);
    notifyListeners();
  }

  void clearActiveMatch() {
    _activeMatch = null;
    _undoStack.clear();
    _storage.setActiveMatchId(null);
    notifyListeners();
  }

  CricketMatch? getMatchById(String id) {
    try {
      return _matches.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  // Snapshot active match state before any mutation
  void _saveSnapshot() {
    if (_activeMatch != null) {
      _undoStack.add(_activeMatch!.deepCopy());
      // Keep max 50 snapshots in memory
      if (_undoStack.length > 50) {
        _undoStack.removeAt(0);
      }
    }
  }

  // Persist current active match
  Future<void> _persist() async {
    if (_activeMatch == null) return;
    _activeMatch!.updatedAt = DateTime.now();
    final index = _matches.indexWhere((m) => m.id == _activeMatch!.id);
    if (index >= 0) {
      _matches[index] = _activeMatch!;
    } else {
      _matches.insert(0, _activeMatch!);
    }
    await _storage.saveSingleMatch(_activeMatch!);
    notifyListeners();
  }

  // ==========================================
  // MATCH CREATION & SETUP FLOW
  // ==========================================

  Future<CricketMatch> createMatch({
    required String name,
    required Team teamA,
    required Team teamB,
    required int totalOvers,
    required MatchType matchType,
    String venue = '',
    required DateTime matchDate,
    String startTime = '10:00 AM',
  }) async {
    final match = CricketMatch(
      id: 'match_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      teamA: teamA,
      teamB: teamB,
      totalOvers: totalOvers,
      matchType: matchType,
      venue: venue,
      matchDate: matchDate,
      startTime: startTime,
      status: MatchStatus.toss,
    );

    _matches.insert(0, match);
    _activeMatch = match;
    _undoStack.clear();
    await _storage.saveSingleMatch(match);
    await _storage.setActiveMatchId(match.id);
    notifyListeners();
    return match;
  }

  Future<void> setToss({
    required String matchId,
    required String tossWinnerId,
    required TossDecision tossDecision,
  }) async {
    final match = getMatchById(matchId);
    if (match == null) return;

    _saveSnapshot();
    match.tossWinnerId = tossWinnerId;
    match.tossDecision = tossDecision;

    // Batting first team calculation
    final tossWinnerTeam = match.tossWinnerId == match.teamA.id ? match.teamA : match.teamB;
    final otherTeam = match.tossWinnerId == match.teamA.id ? match.teamB : match.teamA;

    final battingFirst = tossDecision == TossDecision.bat ? tossWinnerTeam : otherTeam;
    final bowlingFirst = tossDecision == TossDecision.bat ? otherTeam : tossWinnerTeam;

    match.battingFirstTeamId = battingFirst.id;
    match.status = MatchStatus.inning1;

    match.innings1 = InningsData(
      battingTeamId: battingFirst.id,
      battingTeamName: battingFirst.name,
      bowlingTeamId: bowlingFirst.id,
      bowlingTeamName: bowlingFirst.name,
    );

    _activeMatch = match;
    await _persist();
  }

  // Initialize opening players before scoring ball 1
  Future<void> setOpeningPlayers({
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
    bool isSecondInnings = false,
  }) async {
    if (_activeMatch == null) return;
    _saveSnapshot();

    final innings = isSecondInnings ? _activeMatch!.innings2 : _activeMatch!.innings1;
    if (innings == null) return;

    final battingTeam = innings.battingTeamId == _activeMatch!.teamA.id
        ? _activeMatch!.teamA
        : _activeMatch!.teamB;
    final bowlingTeam = innings.bowlingTeamId == _activeMatch!.teamA.id
        ? _activeMatch!.teamA
        : _activeMatch!.teamB;

    innings.currentStrikerId = strikerId;
    innings.currentNonStrikerId = nonStrikerId;
    innings.currentBowlerId = bowlerId;

    // Register batsman scorecards if not present
    final striker = battingTeam.players.firstWhere((p) => p.id == strikerId);
    final nonStriker = battingTeam.players.firstWhere((p) => p.id == nonStrikerId);
    final bowler = bowlingTeam.players.firstWhere((p) => p.id == bowlerId);

    innings.battingScorecards.putIfAbsent(
      strikerId,
      () => BatsmanScorecard(playerId: strikerId, playerName: striker.name, battingOrder: 1),
    );
    innings.battingScorecards.putIfAbsent(
      nonStrikerId,
      () => BatsmanScorecard(playerId: nonStrikerId, playerName: nonStriker.name, battingOrder: 2),
    );

    innings.bowlingScorecards.putIfAbsent(
      bowlerId,
      () => BowlerScorecard(playerId: bowlerId, playerName: bowler.name),
    );

    // Create first over record
    if (innings.overs.isEmpty) {
      innings.overs.add(OverRecord(overNumber: 0, bowlerId: bowlerId));
    }

    await _persist();
  }

  // ==========================================
  // CORE SCORING ENGINE
  // ==========================================

  // Score a normal legal delivery (0, 1, 2, 3, 4, 5, 6)
  Future<void> scoreBall(int runsScored) async {
    if (_activeMatch == null) return;
    final innings = _activeMatch!.currentInnings;
    if (innings == null || innings.isCompleted) return;

    _saveSnapshot();

    final strikerId = innings.currentStrikerId!;
    final nonStrikerId = innings.currentNonStrikerId!;
    final bowlerId = innings.currentBowlerId!;

    final currentOverNum = innings.legalBallsBowled ~/ 6;
    final ballNumInOver = (innings.legalBallsBowled % 6) + 1;

    final batsmanCard = innings.battingScorecards[strikerId]!;
    final bowlerCard = innings.bowlingScorecards[bowlerId]!;

    // 1. Update batsman
    batsmanCard.runs += runsScored;
    batsmanCard.balls += 1;
    if (runsScored == 4) batsmanCard.fours += 1;
    if (runsScored == 6) batsmanCard.sixes += 1;

    // 2. Update bowler
    bowlerCard.legalBallsBowled += 1;
    bowlerCard.runsConceded += runsScored;

    // 3. Update team
    innings.totalRuns += runsScored;
    innings.legalBallsBowled += 1;

    // 4. Create ball record
    final overDisplay = '$currentOverNum.$ballNumInOver';
    String commentary = '$overDisplay - ';
    if (runsScored == 0) {
      commentary += 'Dot ball. ${batsmanCard.playerName} defends solid.';
    } else if (runsScored == 4) {
      commentary += 'FOUR! Beautiful boundary by ${batsmanCard.playerName}.';
    } else if (runsScored == 6) {
      commentary += 'SIX! Maximum! Massive hit by ${batsmanCard.playerName}.';
    } else {
      commentary += '$runsScored run${runsScored > 1 ? "s" : ""} taken by ${batsmanCard.playerName}.';
    }

    final ball = BallRecord(
      id: 'ball_${DateTime.now().microsecondsSinceEpoch}',
      ballNumberInInnings: innings.ballHistory.length + 1,
      overNumber: currentOverNum,
      ballNumberInOver: ballNumInOver,
      isLegal: true,
      batsmanId: strikerId,
      nonStrikerId: nonStrikerId,
      bowlerId: bowlerId,
      runsScored: runsScored,
      extraType: ExtraType.none,
      extraRuns: 0,
      commentary: commentary,
    );

    _addBallToInnings(innings, ball);

    // 5. Rotate strike on odd runs (1, 3, 5)
    if (runsScored % 2 != 0) {
      innings.currentStrikerId = nonStrikerId;
      innings.currentNonStrikerId = strikerId;
    }

    // 6. Over completion check
    _handleOverEndIfNeeded(innings);

    // 7. Auto check match/innings end conditions
    _checkInningsAndMatchCompletion();

    await _persist();
  }

  // Score an Extra delivery (Wide, No Ball, Bye, Leg Bye, Penalty)
  Future<void> scoreExtra({
    required ExtraType type,
    int extraRuns = 1,
    int batRuns = 0,
  }) async {
    if (_activeMatch == null) return;
    final innings = _activeMatch!.currentInnings;
    if (innings == null || innings.isCompleted) return;

    _saveSnapshot();

    final strikerId = innings.currentStrikerId!;
    final nonStrikerId = innings.currentNonStrikerId!;
    final bowlerId = innings.currentBowlerId!;

    final isLegal = (type == ExtraType.bye || type == ExtraType.legBye);
    final currentOverNum = innings.legalBallsBowled ~/ 6;
    final ballNumInOver = isLegal ? (innings.legalBallsBowled % 6) + 1 : (innings.legalBallsBowled % 6);

    final batsmanCard = innings.battingScorecards[strikerId]!;
    final bowlerCard = innings.bowlingScorecards[bowlerId]!;

    String commentary = '';
    final overDisplay = '$currentOverNum.${ballNumInOver == 0 ? 1 : ballNumInOver}';

    switch (type) {
      case ExtraType.wide:
        innings.wides += extraRuns;
        innings.totalRuns += extraRuns;
        bowlerCard.wides += extraRuns;
        bowlerCard.runsConceded += extraRuns;
        commentary = '$overDisplay - Wide ball signaled. +$extraRuns run${extraRuns > 1 ? "s" : ""} to team.';
        break;

      case ExtraType.noBall:
        // No ball: 1 extra run + any bat runs scored
        innings.noBalls += extraRuns;
        bowlerCard.noBalls += 1;
        bowlerCard.runsConceded += (extraRuns + batRuns);
        innings.totalRuns += (extraRuns + batRuns);

        if (batRuns > 0) {
          batsmanCard.runs += batRuns;
          batsmanCard.balls += 1;
          if (batRuns == 4) batsmanCard.fours += 1;
          if (batRuns == 6) batsmanCard.sixes += 1;
          commentary = '$overDisplay - NO BALL! Off the bat for $batRuns run${batRuns > 1 ? "s" : ""}.';
        } else {
          commentary = '$overDisplay - NO BALL called by the umpire.';
        }
        break;

      case ExtraType.bye:
        innings.byes += extraRuns;
        innings.totalRuns += extraRuns;
        innings.legalBallsBowled += 1;
        batsmanCard.balls += 1; // Legal delivery faced
        bowlerCard.legalBallsBowled += 1;
        // Byes do NOT count against the bowler's runs conceded
        commentary = '$overDisplay - Bye! Sneaked through keeper for $extraRuns run${extraRuns > 1 ? "s" : ""}.';
        break;

      case ExtraType.legBye:
        innings.legByes += extraRuns;
        innings.totalRuns += extraRuns;
        innings.legalBallsBowled += 1;
        batsmanCard.balls += 1; // Legal delivery faced
        bowlerCard.legalBallsBowled += 1;
        // Leg Byes do NOT count against bowler's runs conceded
        commentary = '$overDisplay - Leg bye off the pads. $extraRuns run${extraRuns > 1 ? "s" : ""} added.';
        break;

      case ExtraType.penalty:
        innings.penalty += extraRuns;
        innings.totalRuns += extraRuns;
        commentary = '$overDisplay - Penalty awarded: +$extraRuns runs.';
        break;

      case ExtraType.none:
        break;
    }

    final ball = BallRecord(
      id: 'ball_${DateTime.now().microsecondsSinceEpoch}',
      ballNumberInInnings: innings.ballHistory.length + 1,
      overNumber: currentOverNum,
      ballNumberInOver: ballNumInOver,
      isLegal: isLegal,
      batsmanId: strikerId,
      nonStrikerId: nonStrikerId,
      bowlerId: bowlerId,
      runsScored: batRuns,
      extraType: type,
      extraRuns: extraRuns,
      commentary: commentary,
    );

    _addBallToInnings(innings, ball);

    // Rotate strike only when physical running runs are odd
    int physicalRuns = 0;
    if (type == ExtraType.noBall) {
      physicalRuns = batRuns;
    } else if (type == ExtraType.wide) {
      physicalRuns = (extraRuns > 1) ? extraRuns - 1 : 0;
    } else if (type == ExtraType.bye || type == ExtraType.legBye) {
      physicalRuns = extraRuns;
    }

    if (physicalRuns % 2 != 0) {
      innings.currentStrikerId = nonStrikerId;
      innings.currentNonStrikerId = strikerId;
    }

    if (isLegal) {
      _handleOverEndIfNeeded(innings);
    }

    _checkInningsAndMatchCompletion();
    await _persist();
  }

  // Score a Wicket delivery
  Future<void> scoreWicket({
    required WicketType wicketType,
    required String dismissedPlayerId,
    String? fielderId,
    String? nextBatsmanId,
    int runsScored = 0,
    ExtraType extraType = ExtraType.none,
  }) async {
    if (_activeMatch == null) return;
    final innings = _activeMatch!.currentInnings;
    if (innings == null || innings.isCompleted) return;

    _saveSnapshot();

    final strikerId = innings.currentStrikerId!;
    final nonStrikerId = innings.currentNonStrikerId!;
    final bowlerId = innings.currentBowlerId!;

    final isLegal = extraType != ExtraType.wide && extraType != ExtraType.noBall;
    final currentOverNum = innings.legalBallsBowled ~/ 6;
    final ballNumInOver = isLegal ? (innings.legalBallsBowled % 6) + 1 : (innings.legalBallsBowled % 6);

    final dismissedBatsmanCard = innings.battingScorecards[dismissedPlayerId]!;
    final strikerCard = innings.battingScorecards[strikerId]!;
    final bowlerCard = innings.bowlingScorecards[bowlerId]!;

    // 1. Update ball count and runs
    if (isLegal) {
      strikerCard.balls += 1;
      innings.legalBallsBowled += 1;
      bowlerCard.legalBallsBowled += 1;
    }

    if (runsScored > 0) {
      strikerCard.runs += runsScored;
      bowlerCard.runsConceded += runsScored;
      innings.totalRuns += runsScored;
    }

    // 2. Bowler credit rule:
    // Bowled, Caught, LBW, Stumped, Hit Wicket count towards the bowler
    // Run Out and Retired DO NOT count towards the bowler
    final bowlerGetsWicket = (wicketType == WicketType.bowled ||
        wicketType == WicketType.caught ||
        wicketType == WicketType.lbw ||
        wicketType == WicketType.stumped ||
        wicketType == WicketType.hitWicket);

    if (bowlerGetsWicket) {
      bowlerCard.wickets += 1;
    }

    // 3. Update dismissed batsman
    dismissedBatsmanCard.isOut = true;
    dismissedBatsmanCard.wicketType = wicketType;
    dismissedBatsmanCard.bowlerId = bowlerGetsWicket ? bowlerId : null;
    dismissedBatsmanCard.fielderId = fielderId;

    String dismissalText = '';
    final bowlingTeam = innings.bowlingTeamId == _activeMatch!.teamA.id ? _activeMatch!.teamA : _activeMatch!.teamB;
    final fielder = fielderId != null ? bowlingTeam.players.cast<Player?>().firstWhere((p) => p?.id == fielderId, orElse: () => null) : null;

    switch (wicketType) {
      case WicketType.bowled:
        dismissalText = 'b ${bowlerCard.playerName}';
        break;
      case WicketType.caught:
        dismissalText = fielder != null ? 'c ${fielder.name} b ${bowlerCard.playerName}' : 'c & b ${bowlerCard.playerName}';
        break;
      case WicketType.lbw:
        dismissalText = 'lbw b ${bowlerCard.playerName}';
        break;
      case WicketType.stumped:
        dismissalText = fielder != null ? 'st ${fielder.name} b ${bowlerCard.playerName}' : 'st b ${bowlerCard.playerName}';
        break;
      case WicketType.runOut:
        dismissalText = fielder != null ? 'run out (${fielder.name})' : 'run out';
        break;
      case WicketType.hitWicket:
        dismissalText = 'hit wicket b ${bowlerCard.playerName}';
        break;
      case WicketType.retired:
        dismissalText = 'retired out';
        break;
    }
    dismissedBatsmanCard.dismissalText = dismissalText;

    // 4. Team wickets and Fall of Wicket
    innings.wickets += 1;
    innings.fallOfWickets.add(FallOfWicket(
      wicketNumber: innings.wickets,
      score: innings.totalRuns,
      overs: innings.oversString,
      batsmanId: dismissedPlayerId,
      batsmanName: dismissedBatsmanCard.playerName,
    ));

    // 5. Commentary and Ball Record
    final commentary = '$currentOverNum.$ballNumInOver - WICKET! ${dismissedBatsmanCard.playerName} $dismissalText. (${innings.totalRuns}/${innings.wickets})';
    final ball = BallRecord(
      id: 'ball_${DateTime.now().microsecondsSinceEpoch}',
      ballNumberInInnings: innings.ballHistory.length + 1,
      overNumber: currentOverNum,
      ballNumberInOver: ballNumInOver,
      isLegal: isLegal,
      batsmanId: strikerId,
      nonStrikerId: nonStrikerId,
      bowlerId: bowlerId,
      runsScored: runsScored,
      extraType: extraType,
      isWicket: true,
      wicketType: wicketType,
      dismissedPlayerId: dismissedPlayerId,
      fielderId: fielderId,
      commentary: commentary,
    );

    _addBallToInnings(innings, ball);

    // 6. Handle incoming batsman
    final battingTeam = innings.battingTeamId == _activeMatch!.teamA.id ? _activeMatch!.teamA : _activeMatch!.teamB;
    if (nextBatsmanId != null && nextBatsmanId.isNotEmpty) {
      final nextPlayer = battingTeam.players.firstWhere((p) => p.id == nextBatsmanId);
      final nextOrder = innings.battingScorecards.length + 1;
      innings.battingScorecards[nextBatsmanId] = BatsmanScorecard(
        playerId: nextBatsmanId,
        playerName: nextPlayer.name,
        battingOrder: nextOrder,
      );

      if (dismissedPlayerId == strikerId) {
        innings.currentStrikerId = nextBatsmanId;
      } else {
        innings.currentNonStrikerId = nextBatsmanId;
      }
    } else {
      if (dismissedPlayerId == strikerId) {
        innings.currentStrikerId = null;
      } else {
        innings.currentNonStrikerId = null;
      }
    }

    // 7. Rotate strike if odd runs on dismissal (e.g. 1 run taken before run-out)
    if (runsScored % 2 != 0 && innings.currentStrikerId != null && innings.currentNonStrikerId != null) {
      final temp = innings.currentStrikerId;
      innings.currentStrikerId = innings.currentNonStrikerId;
      innings.currentNonStrikerId = temp;
    }

    if (isLegal) {
      _handleOverEndIfNeeded(innings);
    }

    _checkInningsAndMatchCompletion();
    await _persist();
  }

  void _addBallToInnings(InningsData innings, BallRecord ball) {
    innings.ballHistory.add(ball);

    // Add to current over or start a new over
    if (innings.overs.isEmpty) {
      innings.overs.add(OverRecord(overNumber: 0, bowlerId: ball.bowlerId));
    }
    var currentOver = innings.overs.last;
    if (currentOver.overNumber != ball.overNumber) {
      currentOver = OverRecord(overNumber: ball.overNumber, bowlerId: ball.bowlerId);
      innings.overs.add(currentOver);
    }
    currentOver.balls.add(ball);
  }

  void _handleOverEndIfNeeded(InningsData innings) {
    if (innings.legalBallsBowled > 0 && innings.legalBallsBowled % 6 == 0) {
      // Completed over!
      // 1. Swap strike at the end of the over
      final temp = innings.currentStrikerId;
      innings.currentStrikerId = innings.currentNonStrikerId;
      innings.currentNonStrikerId = temp;

      // 2. Check if the over had maidens
      final lastOver = innings.overs.isNotEmpty ? innings.overs.last : null;
      if (lastOver != null && lastOver.isMaiden) {
        final bowlerCard = innings.bowlingScorecards[lastOver.bowlerId];
        if (bowlerCard != null) {
          bowlerCard.maidens += 1;
        }
      }
    }
  }

  // Manually swap striker and non-striker
  Future<void> swapStrike() async {
    if (_activeMatch == null) return;
    final innings = _activeMatch!.currentInnings;
    if (innings == null) return;

    _saveSnapshot();
    final temp = innings.currentStrikerId;
    innings.currentStrikerId = innings.currentNonStrikerId;
    innings.currentNonStrikerId = temp;
    await _persist();
  }

  // Change or select new Bowler
  Future<void> changeBowler(String newBowlerId) async {
    if (_activeMatch == null) return;
    final innings = _activeMatch!.currentInnings;
    if (innings == null) return;

    _saveSnapshot();
    innings.currentBowlerId = newBowlerId;

    final bowlingTeam = innings.bowlingTeamId == _activeMatch!.teamA.id
        ? _activeMatch!.teamA
        : _activeMatch!.teamB;
    final bowler = bowlingTeam.players.firstWhere((p) => p.id == newBowlerId);

    innings.bowlingScorecards.putIfAbsent(
      newBowlerId,
      () => BowlerScorecard(playerId: newBowlerId, playerName: bowler.name),
    );

    // If starting a new over
    final currentOverNum = innings.legalBallsBowled ~/ 6;
    if (innings.overs.isEmpty || innings.overs.last.isCompleted) {
      innings.overs.add(OverRecord(overNumber: currentOverNum, bowlerId: newBowlerId));
    }

    await _persist();
  }

  // Change or select incoming Batsman
  Future<void> changeBatsman({
    required bool isStriker,
    required String newPlayerId,
  }) async {
    if (_activeMatch == null) return;
    final innings = _activeMatch!.currentInnings;
    if (innings == null) return;

    _saveSnapshot();
    final battingTeam = innings.battingTeamId == _activeMatch!.teamA.id
        ? _activeMatch!.teamA
        : _activeMatch!.teamB;
    final player = battingTeam.players.firstWhere((p) => p.id == newPlayerId);

    innings.battingScorecards.putIfAbsent(
      newPlayerId,
      () => BatsmanScorecard(
        playerId: newPlayerId,
        playerName: player.name,
        battingOrder: innings.battingScorecards.length + 1,
      ),
    );

    if (isStriker) {
      innings.currentStrikerId = newPlayerId;
    } else {
      innings.currentNonStrikerId = newPlayerId;
    }

    await _persist();
  }

  // Manual End Over
  Future<void> endOver() async {
    if (_activeMatch == null) return;
    final innings = _activeMatch!.currentInnings;
    if (innings == null) return;

    _saveSnapshot();
    final temp = innings.currentStrikerId;
    innings.currentStrikerId = innings.currentNonStrikerId;
    innings.currentNonStrikerId = temp;
    await _persist();
  }

  // ==========================================
  // INNINGS BREAK & MATCH COMPLETION
  // ==========================================

  void _checkInningsAndMatchCompletion() {
    if (_activeMatch == null) return;

    final totalBalls = _activeMatch!.totalOvers * 6;

    // 1. First Innings Check
    if (_activeMatch!.status == MatchStatus.inning1) {
      final inn1 = _activeMatch!.innings1;
      if (inn1 == null) return;

      final battingTeam = inn1.battingTeamId == _activeMatch!.teamA.id ? _activeMatch!.teamA : _activeMatch!.teamB;
      final maxWickets = battingTeam.players.length > 1 ? battingTeam.players.length - 1 : 10;

      final isAllOut = inn1.wickets >= maxWickets;
      final isOversCompleted = inn1.legalBallsBowled >= totalBalls;

      if (isAllOut || isOversCompleted) {
        inn1.isCompleted = true;
        _activeMatch!.status = MatchStatus.inningBreak;
        _activeMatch!.targetRuns = inn1.totalRuns + 1;
      }
    }

    // 2. Second Innings Check
    else if (_activeMatch!.status == MatchStatus.inning2) {
      final inn2 = _activeMatch!.innings2;
      final target = _activeMatch!.targetRuns;
      if (inn2 == null || target == null) return;

      final battingTeam = inn2.battingTeamId == _activeMatch!.teamA.id ? _activeMatch!.teamA : _activeMatch!.teamB;
      final bowlingTeam = inn2.bowlingTeamId == _activeMatch!.teamA.id ? _activeMatch!.teamA : _activeMatch!.teamB;
      final maxWickets = battingTeam.players.length > 1 ? battingTeam.players.length - 1 : 10;

      final isTargetChased = inn2.totalRuns >= target;
      final isAllOut = inn2.wickets >= maxWickets;
      final isOversCompleted = inn2.legalBallsBowled >= totalBalls;

      if (isTargetChased || isAllOut || isOversCompleted) {
        inn2.isCompleted = true;
        _activeMatch!.status = MatchStatus.completed;

        // Determine winner and margin
        if (isTargetChased) {
          final wicketsRemaining = maxWickets - inn2.wickets;
          _activeMatch!.winnerTeamId = battingTeam.id;
          _activeMatch!.winMargin = '$wicketsRemaining wicket${wicketsRemaining > 1 ? "s" : ""}';
          _activeMatch!.resultSummary = '${battingTeam.name} won by ${_activeMatch!.winMargin}';
        } else if (inn2.totalRuns == target - 1) {
          _activeMatch!.winnerTeamId = null;
          _activeMatch!.winMargin = 'Tied';
          _activeMatch!.resultSummary = 'Match Tied!';
        } else {
          final runMargin = (target - 1) - inn2.totalRuns;
          _activeMatch!.winnerTeamId = bowlingTeam.id;
          _activeMatch!.winMargin = '$runMargin runs';
          _activeMatch!.resultSummary = '${bowlingTeam.name} won by ${_activeMatch!.winMargin}';
        }

        // Calculate Player of the Match
        _calculatePlayerOfTheMatch();
      }
    }
  }

  Future<void> endInningsManually() async {
    if (_activeMatch == null) return;
    _saveSnapshot();

    if (_activeMatch!.status == MatchStatus.inning1) {
      final inn1 = _activeMatch!.innings1;
      if (inn1 != null) {
        inn1.isCompleted = true;
        _activeMatch!.status = MatchStatus.inningBreak;
        _activeMatch!.targetRuns = inn1.totalRuns + 1;
      }
    } else if (_activeMatch!.status == MatchStatus.inning2) {
      final inn2 = _activeMatch!.innings2;
      if (inn2 != null) {
        inn2.isCompleted = true;
        _activeMatch!.status = MatchStatus.completed;
        _checkInningsAndMatchCompletion();
      }
    }
    await _persist();
  }

  // Start Second Innings
  Future<void> startSecondInnings({
    required String strikerId,
    required String nonStrikerId,
    required String bowlerId,
  }) async {
    if (_activeMatch == null) return;
    _saveSnapshot();

    final battingFirstTeam = _activeMatch!.battingFirstTeam!;
    final bowlingFirstTeam = _activeMatch!.bowlingFirstTeam!;

    _activeMatch!.status = MatchStatus.inning2;
    _activeMatch!.innings2 = InningsData(
      battingTeamId: bowlingFirstTeam.id,
      battingTeamName: bowlingFirstTeam.name,
      bowlingTeamId: battingFirstTeam.id,
      bowlingTeamName: battingFirstTeam.name,
    );

    await setOpeningPlayers(
      strikerId: strikerId,
      nonStrikerId: nonStrikerId,
      bowlerId: bowlerId,
      isSecondInnings: true,
    );
  }

  // Calculate Player of the Match based on top all-round impact (Runs + Wickets * 25)
  void _calculatePlayerOfTheMatch() {
    if (_activeMatch == null) return;
    final allPlayers = [..._activeMatch!.teamA.players, ..._activeMatch!.teamB.players];
    String? bestPlayerId;
    double maxPoints = -1;

    for (final player in allPlayers) {
      double points = 0;
      // Batting points in inn1 & inn2
      for (final inn in [_activeMatch!.innings1, _activeMatch!.innings2]) {
        if (inn != null && inn.battingScorecards.containsKey(player.id)) {
          final b = inn.battingScorecards[player.id]!;
          points += b.runs;
          points += b.fours * 2.0;
          points += b.sixes * 3.5;
          if (b.runs >= 50) points += 20;
          if (b.runs >= 100) points += 40;
        }
        if (inn != null && inn.bowlingScorecards.containsKey(player.id)) {
          final w = inn.bowlingScorecards[player.id]!;
          points += w.wickets * 25.0;
          points += w.maidens * 10.0;
        }
      }
      if (points > maxPoints) {
        maxPoints = points;
        bestPlayerId = player.id;
      }
    }
    _activeMatch!.playerOfTheMatchId = bestPlayerId;
  }

  // ==========================================
  // UNDO ENGINE
  // ==========================================

  Future<bool> undo() async {
    if (_undoStack.isEmpty) return false;

    // Restore previous snapshot
    final previousState = _undoStack.removeLast();
    _activeMatch = previousState;

    final index = _matches.indexWhere((m) => m.id == previousState.id);
    if (index >= 0) {
      _matches[index] = previousState;
    }
    await _storage.saveSingleMatch(previousState);
    notifyListeners();
    return true;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ys_score_11/models/cricket_match.dart';
import 'package:ys_score_11/models/team.dart';
import 'package:ys_score_11/models/player.dart';
import 'package:ys_score_11/models/ball_record.dart';
import 'package:ys_score_11/providers/scoring_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScoringProvider provider;
  late Team teamA;
  late Team teamB;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = ScoringProvider();

    teamA = Team(
      id: 'team_a',
      name: 'Young Storms XI',
      shortName: 'YS',
      players: List.generate(
        11,
        (i) => Player(id: 'ys_$i', name: 'YS Player $i', jerseyNumber: i + 1),
      ),
    );

    teamB = Team(
      id: 'team_b',
      name: 'Thunderbolts CC',
      shortName: 'TB',
      players: List.generate(
        11,
        (i) => Player(id: 'tb_$i', name: 'TB Player $i', jerseyNumber: i + 1),
      ),
    );

    await provider.init([teamA, teamB]);
  });

  test('Create match, set toss, and set opening players', () async {
    final match = await provider.createMatch(
      name: 'Test Final',
      teamA: teamA,
      teamB: teamB,
      totalOvers: 20,
      matchType: MatchType.t20,
      venue: 'Young Storms Arena',
      matchDate: DateTime.now(),
    );

    expect(match.status, MatchStatus.toss);
    expect(provider.activeMatch?.id, match.id);

    // Set toss: Team A won and bat first
    await provider.setToss(
      matchId: match.id,
      tossWinnerId: teamA.id,
      tossDecision: TossDecision.bat,
    );

    expect(provider.activeMatch?.status, MatchStatus.inning1);
    expect(provider.activeMatch?.battingFirstTeamId, teamA.id);

    // Set opening players
    await provider.setOpeningPlayers(
      strikerId: 'ys_0',
      nonStrikerId: 'ys_1',
      bowlerId: 'tb_0',
    );

    final inn = provider.activeMatch!.innings1!;
    expect(inn.currentStrikerId, 'ys_0');
    expect(inn.currentNonStrikerId, 'ys_1');
    expect(inn.currentBowlerId, 'tb_0');
    expect(inn.battingScorecards.containsKey('ys_0'), true);
    expect(inn.battingScorecards.containsKey('ys_1'), true);
    expect(inn.bowlingScorecards.containsKey('tb_0'), true);
  });

  test('Normal ball scoring & strike rotation on odd runs', () async {
    final match = await provider.createMatch(
      name: 'Strike Test',
      teamA: teamA,
      teamB: teamB,
      totalOvers: 20,
      matchType: MatchType.t20,
      matchDate: DateTime.now(),
    );

    await provider.setToss(
      matchId: match.id,
      tossWinnerId: teamA.id,
      tossDecision: TossDecision.bat,
    );

    await provider.setOpeningPlayers(
      strikerId: 'ys_0',
      nonStrikerId: 'ys_1',
      bowlerId: 'tb_0',
    );

    // Ball 1: 1 run -> strike should rotate to ys_1
    await provider.scoreBall(1);
    var inn = provider.activeMatch!.innings1!;
    expect(inn.totalRuns, 1);
    expect(inn.legalBallsBowled, 1);
    expect(inn.currentStrikerId, 'ys_1');
    expect(inn.currentNonStrikerId, 'ys_0');
    expect(inn.battingScorecards['ys_0']!.runs, 1);
    expect(inn.battingScorecards['ys_0']!.balls, 1);

    // Ball 2: 4 runs -> boundary by ys_1, strike remains with ys_1
    await provider.scoreBall(4);
    inn = provider.activeMatch!.innings1!;
    expect(inn.totalRuns, 5);
    expect(inn.legalBallsBowled, 2);
    expect(inn.currentStrikerId, 'ys_1');
    expect(inn.battingScorecards['ys_1']!.runs, 4);
    expect(inn.battingScorecards['ys_1']!.fours, 1);

    // Ball 3: 2 runs -> strike remains with ys_1
    await provider.scoreBall(2);
    inn = provider.activeMatch!.innings1!;
    expect(inn.totalRuns, 7);
    expect(inn.currentStrikerId, 'ys_1');
    expect(inn.battingScorecards['ys_1']!.runs, 6);
  });

  test('Extras scoring: Wide and No Ball rules', () async {
    final match = await provider.createMatch(
      name: 'Extras Test',
      teamA: teamA,
      teamB: teamB,
      totalOvers: 20,
      matchType: MatchType.t20,
      matchDate: DateTime.now(),
    );

    await provider.setToss(
      matchId: match.id,
      tossWinnerId: teamA.id,
      tossDecision: TossDecision.bat,
    );

    await provider.setOpeningPlayers(
      strikerId: 'ys_0',
      nonStrikerId: 'ys_1',
      bowlerId: 'tb_0',
    );

    // Wide delivery: 1 extra run, legal balls NOT incremented, batsman balls NOT incremented
    await provider.scoreExtra(type: ExtraType.wide, extraRuns: 1);
    var inn = provider.activeMatch!.innings1!;
    expect(inn.totalRuns, 1);
    expect(inn.wides, 1);
    expect(inn.legalBallsBowled, 0);
    expect(inn.battingScorecards['ys_0']!.balls, 0);
    expect(inn.bowlingScorecards['tb_0']!.wides, 1);
    expect(inn.bowlingScorecards['tb_0']!.runsConceded, 1);

    // No Ball + 4 runs off the bat: 1 extra + 4 runs = 5 total runs
    await provider.scoreExtra(type: ExtraType.noBall, extraRuns: 1, batRuns: 4);
    inn = provider.activeMatch!.innings1!;
    expect(inn.totalRuns, 6); // 1 wide + 1 nb + 4 bat runs
    expect(inn.noBalls, 1);
    expect(inn.legalBallsBowled, 0); // No ball is illegal delivery
    expect(inn.battingScorecards['ys_0']!.runs, 4);
    expect(inn.battingScorecards['ys_0']!.fours, 1);
  });

  test('Wicket scoring & bowler credit rules', () async {
    final match = await provider.createMatch(
      name: 'Wicket Test',
      teamA: teamA,
      teamB: teamB,
      totalOvers: 20,
      matchType: MatchType.t20,
      matchDate: DateTime.now(),
    );

    await provider.setToss(
      matchId: match.id,
      tossWinnerId: teamA.id,
      tossDecision: TossDecision.bat,
    );

    await provider.setOpeningPlayers(
      strikerId: 'ys_0',
      nonStrikerId: 'ys_1',
      bowlerId: 'tb_0',
    );

    // Bowled wicket -> credits bowler
    await provider.scoreWicket(
      wicketType: WicketType.bowled,
      dismissedPlayerId: 'ys_0',
      nextBatsmanId: 'ys_2',
    );

    var inn = provider.activeMatch!.innings1!;
    expect(inn.wickets, 1);
    expect(inn.legalBallsBowled, 1);
    expect(inn.battingScorecards['ys_0']!.isOut, true);
    expect(inn.battingScorecards['ys_0']!.dismissalText, 'b TB Player 0');
    expect(inn.bowlingScorecards['tb_0']!.wickets, 1);
    expect(inn.currentStrikerId, 'ys_2'); // Incoming batsman takes strike

    // Run Out wicket -> does NOT credit bowler
    await provider.scoreWicket(
      wicketType: WicketType.runOut,
      dismissedPlayerId: 'ys_1',
      nextBatsmanId: 'ys_3',
    );

    inn = provider.activeMatch!.innings1!;
    expect(inn.wickets, 2);
    expect(inn.legalBallsBowled, 2);
    expect(inn.battingScorecards['ys_1']!.isOut, true);
    expect(inn.battingScorecards['ys_1']!.dismissalText.contains('run out'), true);
    expect(inn.bowlingScorecards['tb_0']!.wickets, 1); // Still 1 wicket for bowler
  });

  test('Full snapshot Undo functionality', () async {
    final match = await provider.createMatch(
      name: 'Undo Test',
      teamA: teamA,
      teamB: teamB,
      totalOvers: 20,
      matchType: MatchType.t20,
      matchDate: DateTime.now(),
    );

    await provider.setToss(
      matchId: match.id,
      tossWinnerId: teamA.id,
      tossDecision: TossDecision.bat,
    );

    await provider.setOpeningPlayers(
      strikerId: 'ys_0',
      nonStrikerId: 'ys_1',
      bowlerId: 'tb_0',
    );

    // Score 6
    await provider.scoreBall(6);
    expect(provider.activeMatch!.innings1!.totalRuns, 6);
    expect(provider.activeMatch!.innings1!.legalBallsBowled, 1);
    expect(provider.canUndo, true);

    // Undo -> should cleanly roll back to 0 runs and 0 balls
    final undone = await provider.undo();
    expect(undone, true);
    expect(provider.activeMatch!.innings1!.totalRuns, 0);
    expect(provider.activeMatch!.innings1!.legalBallsBowled, 0);
    expect(provider.activeMatch!.innings1!.battingScorecards['ys_0']!.runs, 0);
    expect(provider.activeMatch!.innings1!.battingScorecards['ys_0']!.balls, 0);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/teams_provider.dart';
import 'providers/tournament_provider.dart';
import 'providers/scoring_provider.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation for optimal single-handed ground scoring
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set premium dark status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const YsScore11App());
}

class YsScore11App extends StatefulWidget {
  const YsScore11App({super.key});

  @override
  State<YsScore11App> createState() => _YsScore11AppState();
}

class _YsScore11AppState extends State<YsScore11App> {
  late final AuthProvider _authProvider;
  late final TeamsProvider _teamsProvider;
  late final TournamentProvider _tournamentProvider;
  late final ScoringProvider _scoringProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _teamsProvider = TeamsProvider();
    _tournamentProvider = TournamentProvider();
    _scoringProvider = ScoringProvider();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _authProvider.init();
    await _teamsProvider.loadTeams();
    await _scoringProvider.init(_teamsProvider.teams);
    await _tournamentProvider.loadTournaments(_teamsProvider.teams);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _teamsProvider),
        ChangeNotifierProvider.value(value: _tournamentProvider),
        ChangeNotifierProvider.value(value: _scoringProvider),
      ],
      child: MaterialApp(
        title: 'YS SCORE 11',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

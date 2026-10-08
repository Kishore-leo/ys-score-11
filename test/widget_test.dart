import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ys_score_11/main.dart';

void main() {
  testWidgets('App renders SplashScreen on launch with YS SCORE 11', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const YsScore11App());
    await tester.pump(const Duration(milliseconds: 500));

    // Expect to find the app title on SplashScreen
    expect(find.text('YS SCORE 11'), findsOneWidget);
    expect(find.text('CRICKET MATCH SCORING SYSTEM'), findsOneWidget);

    // Advance past splash animations and timers to clean up test tree
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}

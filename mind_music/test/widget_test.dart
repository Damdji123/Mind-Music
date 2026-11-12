import 'package:flutter_test/flutter_test.dart';
import 'package:mind_music/core/services/preferences_service.dart';
import 'package:mind_music/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test initializes MindMusicApp and loads SplashScreen', (WidgetTester tester) async {
    final prefs = PreferencesService();
    await prefs.init();

    await tester.pumpWidget(MindMusicApp(preferencesService: prefs));
    await tester.pump();

    // Verify splash screen branding is rendered
    expect(find.text('Mind-Music'), findsOneWidget);
    expect(find.text('Your Media. Your AI. Your Way.'), findsOneWidget);
  });
}

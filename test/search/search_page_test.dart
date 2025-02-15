import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:count_me_in/src/search/search_page.dart';
import 'package:provider/provider.dart';
import 'package:count_me_in/src/playback/audio_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SearchPage', () {
    late AudioController audioController;

    setUp(() {
      audioController = AudioController();
    });

    Future<void> pumpSearchPage(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<AudioController>.value(value: audioController),
            ],
            child: const SearchPage(accessToken: 'test_token'),
          ),
        ),
      );
    }

    testWidgets('renders search input field', (WidgetTester tester) async {
      await pumpSearchPage(tester);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows search button', (WidgetTester tester) async {
      await pumpSearchPage(tester);
      expect(find.byType(IconButton), findsOneWidget);
    });
  });
}

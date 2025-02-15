import 'package:flutter_test/flutter_test.dart';
import 'package:count_me_in/src/search/search_page.dart';
import 'package:count_me_in/src/playback/audio_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:integration_test/integration_test.dart';
import 'helpers/prism_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Search Integration Tests', () {
    late AudioController audioController;

    setUp(() async {
      audioController = AudioController();
      audioController.setAccessToken('mock_token');
      try {
        await audioController.initialize();
      } catch (e) {
        // Initialize might fail in tests due to SoLoud, but we can still test the API calls
        print('Warning: AudioController initialization failed: $e');
      }
    });

    tearDown(() async {
      audioController.dispose();
    });

    Future<void> pumpSearchPage(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<AudioController>.value(value: audioController),
            ],
            child: const SearchPage(accessToken: 'mock_token'),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('renders search input field', (WidgetTester tester) async {
      await pumpSearchPage(tester);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('performs search and shows results', (WidgetTester tester) async {
      await pumpSearchPage(tester);

      // Enter search query
      await tester.enterText(find.byType(TextField), 'test query');
      await tester.pump();

      // Tap search button
      await tester.tap(find.byType(IconButton));
      await tester.pump(); // Start loading
      
      // Verify loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for search results
      await tester.pump(Duration(seconds: 2));

      // Loading indicator should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Should show some results
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('can select track from search results', (WidgetTester tester) async {
      await pumpSearchPage(tester);

      // Perform search
      await tester.enterText(find.byType(TextField), 'test query');
      await tester.pump();
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      await tester.pump(Duration(seconds: 2));

      // Verify we have results
      expect(find.byType(ListTile), findsWidgets);

      // Select first result
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // Should navigate away from search page
      expect(find.byType(SearchPage), findsNothing);
    });

    testWidgets('handles search errors gracefully', (WidgetTester tester) async {
      await pumpSearchPage(tester);

      // Enter an invalid query that should trigger an error
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      // Should show error message
      expect(find.textContaining('Error'), findsOneWidget);
    });
  });
}

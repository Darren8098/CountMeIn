import 'package:flutter_test/flutter_test.dart';
import 'package:count_me_in/src/playback/audio_controller.dart';
import 'package:count_me_in/src/playback/playback_page.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'helpers/prism_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Playback Integration Tests', () {
    late AudioController audioController;
    // late PrismServer prismServer;

    setUp(() async {
      // prismServer = PrismServer(port: 4011);
      // await prismServer.start();

      audioController = AudioController();
      audioController.setAccessToken('mock_token');
      try {
        await audioController.initialize();
      } catch (e) {
        print('Warning: AudioController initialization failed: $e');
      }
    });

    tearDown(() async {
      audioController.dispose();
      // await prismServer.stop();
    });

    Future<void> pumpBpmSettingPage(WidgetTester tester, {String? trackId}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BpmSettingPage(
            trackName: 'Test Track',
            trackId: trackId ?? 'mock_track_id',
            audioController: audioController,
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('renders BPM controls', (WidgetTester tester) async {
      await pumpBpmSettingPage(tester);
      
      expect(find.text('Set BPM'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Count me in'), findsOneWidget);
    });

    testWidgets('can start playback with count-in', (WidgetTester tester) async {
      await pumpBpmSettingPage(tester);

      // Start count-in
      await tester.tap(find.text('Count me in'));
      await tester.pump();

      // Should show counting state
      expect(find.text('Ready'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for count-in to finish
      await tester.pump(Duration(seconds: 2));

      // Should show playback controls
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(2)); // BPM and progress sliders
    });

    testWidgets('can pause playback', (WidgetTester tester) async {
      await pumpBpmSettingPage(tester);

      // Start playback with count-in
      await tester.tap(find.text('Count me in'));
      await tester.pump(Duration(seconds: 2));

      // Pause playback
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      // Should show play button
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('can resume from paused state', (WidgetTester tester) async {
      await pumpBpmSettingPage(tester);

      // Start playback with count-in
      await tester.tap(find.text('Count me in'));
      await tester.pump(Duration(seconds: 2));

      // Pause playback
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      // Resume playback
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Should show pause button
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('handles playback errors gracefully', (WidgetTester tester) async {
      await pumpBpmSettingPage(tester, trackId: 'invalid_track_id');

      // Try to start playback
      await tester.tap(find.text('Count me in'));
      await tester.pump(Duration(seconds: 2));

      // Should show error message
      expect(find.textContaining('Failed to play audio'), findsOneWidget);
    });
  });
}

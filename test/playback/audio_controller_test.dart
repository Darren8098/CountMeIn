import 'package:flutter_test/flutter_test.dart';
import 'package:count_me_in/src/playback/audio_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioController', () {
    late AudioController audioController;

    setUp(() {
      audioController = AudioController();
    });

    test('initial state is not initialized', () {
      expect(audioController.isInitialized, isFalse);
    });

    test('initial playback state is not playing', () {
      expect(audioController.isPlaying, isFalse);
    });

    test('initial position is zero', () {
      expect(audioController.currentPosition, equals(Duration.zero));
    });

    test('initial duration is zero', () {
      expect(audioController.totalDuration, equals(Duration.zero));
    });

    test('startMusic fails when not initialized', () async {
      await expectLater(
        () => audioController.startMusic('track_id'),
        throwsA(isA<StateError>()),
      );
    });

    test('pauseMusic fails when not initialized', () async {
      await expectLater(
        () => audioController.pauseMusic(),
        throwsA(isA<StateError>()),
      );
    });
  });
}

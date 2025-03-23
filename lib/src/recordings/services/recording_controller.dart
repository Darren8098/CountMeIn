import 'dart:async';
import 'dart:io';
import 'package:count_me_in/src/recordings/services/recordings_repository.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class RecordingController {
  final RecordingsRepository _recordingRepository;

  static final Logger _log = Logger('RecordingController');
  final RecorderController _recorderController = RecorderController();
  String? _currentRecordingPath;

  bool get isRecording => _recorderController.isRecording;
  String? get currentRecordingPath => _currentRecordingPath;
  RecorderController get recorderController => _recorderController;

  RecordingController({required RecordingsRepository recordingRepository})
    : _recordingRepository = recordingRepository;

  Future<void> startRecording(String trackId) async {
    if (isRecording) {
      _log.warning('Already recording');
      return;
    }

    try {
      if (!await _recorderController.checkPermission()) {
        throw StateError('Microphone permission not granted');
      }

      final appDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${appDir.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${recordingsDir.path}/$trackId-$timestamp.m4a';

      await _recorderController.record(path: _currentRecordingPath);
      _log.info('Started recording to $_currentRecordingPath');
    } catch (e) {
      _log.severe('Failed to start recording', e);
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    if (!isRecording) {
      _log.warning('Not currently recording');
      return null;
    }

    try {
      await _recorderController.stop();

      final recordingPath = _currentRecordingPath;
      _currentRecordingPath = null;

      _log.info('Stopped recording');
      return recordingPath;
    } catch (e) {
      _log.severe('Failed to stop recording', e);
      rethrow;
    }
  }

  Future<void> saveRecording(
    String recordingPath,
    String trackId,
    String trackName,
  ) {
    return _recordingRepository.addRecording(
      filePath: recordingPath,
      trackId: trackId,
      trackName: trackName,
    );
  }

  Future<void> dispose() async {
    if (isRecording) {
      await stopRecording();
    }
    _recorderController.dispose();
  }
}

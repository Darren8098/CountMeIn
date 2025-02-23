import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordingController {
  static final Logger _log = Logger('RecordingController');
  final _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<void> startRecording(String trackId) async {
    if (_isRecording) {
      _log.warning('Already recording');
      return;
    }

    try {
      // Check permissions
      if (!await _audioRecorder.hasPermission()) {
        throw StateError('Microphone permission not granted');
      }

      // Create recordings directory if it doesn't exist
      final appDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${appDir.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      // Generate unique filename using timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${recordingsDir.path}/$trackId-$timestamp.m4a';

      await _audioRecorder.start(
        RecordConfig(),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _log.info('Started recording to $_currentRecordingPath');
    } catch (e) {
      _log.severe('Failed to start recording', e);
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) {
      _log.warning('Not currently recording');
      return null;
    }

    try {
      await _audioRecorder.stop();
      _isRecording = false;

      final recordingPath = _currentRecordingPath;
      _currentRecordingPath = null;

      _log.info('Stopped recording');
      return recordingPath;
    } catch (e) {
      _log.severe('Failed to stop recording', e);
      rethrow;
    }
  }

  Future<void> dispose() async {
    if (_isRecording) {
      await stopRecording();
    }
  }
}

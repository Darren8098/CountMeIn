import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:count_me_in/src/recording/recording.dart';

class RecordingsRepository extends ChangeNotifier {
  static final Logger _log = Logger('RecordingService');
  static const String _metadataFileName = 'recordings_metadata.json';
  List<Recording> _recordings = [];

  List<Recording> get recordings => List.unmodifiable(_recordings);

  Future<void> initialize() async {
    try {
      await _loadMetadata();
    } catch (e) {
      _log.warning('Failed to load recordings metadata', e);
      // Start with empty list if loading fails
      _recordings = [];
    }
  }

  Future<void> _loadMetadata() async {
    final file = await _getMetadataFile();
    if (await file.exists()) {
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = json.decode(jsonString);
      _recordings = jsonList.map((json) => Recording.fromJson(json)).toList();
      _recordings.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      notifyListeners();
    }
  }

  Future<void> _saveMetadata() async {
    final file = await _getMetadataFile();
    final jsonString = json.encode(_recordings.map((r) => r.toJson()).toList());
    await file.writeAsString(jsonString);
    notifyListeners();
  }

  Future<File> _getMetadataFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/$_metadataFileName');
  }

  Future<Recording> addRecording({
    required String filePath,
    required String trackId,
    required String trackName,
  }) async {
    final recording = Recording(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      filePath: filePath,
      trackId: trackId,
      trackName: trackName,
      recordedAt: DateTime.now(),
    );

    _recordings.insert(0, recording);
    await _saveMetadata();
    _log.info('Added new recording: ${recording.id}');
    return recording;
  }

  Future<void> deleteRecording(String recordingId) async {
    final recording = _recordings.firstWhere((r) => r.id == recordingId);

    // Delete the audio file
    final file = File(recording.filePath);
    if (await file.exists()) {
      await file.delete();
    }

    // Remove from list and save metadata
    _recordings.removeWhere((r) => r.id == recordingId);
    await _saveMetadata();
    _log.info('Deleted recording: $recordingId');
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:count_me_in/src/recording/recording_controller.dart';
import 'package:count_me_in/src/recording/recording_service.dart';

class AudioController {
  static final Logger _log = Logger('AudioController');

  final String baseUrl;
  final RecordingController _recordingController;
  final RecordingService _recordingService;
  String? _currentTrackName;

  AudioController(
    this.baseUrl, {
    required RecordingService recordingService,
  })  : _recordingController = RecordingController(),
        _recordingService = recordingService;

  SoLoud? _soloud;
  bool _isInitialized = false;
  String? _accessToken;
  String? _currentTrackId;
  String? _deviceId;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  Future<void> initialize() async {
    try {
      _soloud = SoLoud.instance;
      await _soloud!.init();
      await _getAvailableDevices();
      await _recordingService.initialize();
      _isInitialized = true;
      _log.info('Audio system initialized successfully');
    } catch (e) {
      _log.severe('Failed to initialize audio system', e);
      rethrow;
    }
  }

  Future<void> _getAvailableDevices() async {
    if (_accessToken == null) {
      throw StateError('Access token not set');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/me/player/devices'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      final devices = jsonDecode(response.body)['devices'] as List;
      if (devices.isNotEmpty) {
        _deviceId = devices.first['id'];
      }
    } else {
      throw Exception(
          'Failed to get available devices ${response.statusCode} ${response.body}');
    }
  }

  void setAccessToken(String token) {
    _accessToken = token;
  }

  Future<void> startMusic(String trackId, {Duration? startAt}) async {
    if (!_isInitialized) {
      throw StateError('AudioController not initialized');
    }

    if (_accessToken == null) {
      throw StateError('Access token not set');
    }

    try {
      // First get the track metadata to get its duration
      final trackResponse = await http.get(
        Uri.parse('$baseUrl/tracks/$trackId'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (trackResponse.statusCode == 200) {
        final trackData = jsonDecode(trackResponse.body);
        _totalDuration = Duration(milliseconds: trackData['duration_ms']);
        _currentTrackName = trackData['name'];
      } else {
        _log.warning('Failed to get track metadata: ${trackResponse.statusCode}, "${trackResponse.body}"');
      }

      // Start recording before playing the track
      await _recordingController.startRecording(trackId);

      final response = await http.put(
        Uri.parse(
            '$baseUrl/me/player/play${_deviceId != null ? '?device_id=$_deviceId' : ''}'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'uris': ['spotify:track:$trackId'],
          'position_ms': startAt?.inMilliseconds ?? 0,
        }),
      );

      if (response.statusCode == 204) {
        _currentTrackId = trackId;
        _currentPosition = startAt ?? Duration.zero;
        _isPlaying = true;
        _startPositionTimer();
        _log.info('Started music playback for track: $trackId');
      } else {
        throw Exception(
            'Failed to start playback: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _log.severe('Failed to start music playback', e);
      rethrow;
    }
  }

  Future<void> pauseMusic() async {
    if (!_isInitialized) {
      throw StateError('AudioController not initialized');
    }

    if (_accessToken == null) {
      throw StateError('Access token not set');
    }

    if (!_isPlaying) return;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/me/player/pause'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        _isPlaying = false;
        _stopPositionTimer();

        // Stop recording and save metadata
        if (_recordingController.isRecording) {
          final recordingPath = await _recordingController.stopRecording();
          if (recordingPath != null && _currentTrackId != null && _currentTrackName != null) {
            await _recordingService.addRecording(
              filePath: recordingPath,
              trackId: _currentTrackId!,
              trackName: _currentTrackName!,
            );
          }
        }

        _log.info('Paused music playback');
      } else {
        throw Exception(
            'Failed to pause playback: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      _log.warning('Failed to pause music', e);
      rethrow;
    }
  }

  Future<void> resumeMusic() async {
    if (!_isInitialized || _isPlaying) return;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/me/player/play'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 204) {
        _isPlaying = true;
        _startPositionTimer();
        _log.info('Resumed music playback');
      } else {
        throw Exception(
            'Failed to resume playback: ${response.statusCode}, "${response.body}"');
      }
    } catch (e) {
      _log.warning('Failed to resume music ${e.toString()}', e);
      rethrow;
    }
  }

  Timer? _positionTimer;

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(Duration(seconds: 1), (_) {
      // Update position locally every second
      if (_isPlaying) {
        _currentPosition += Duration(seconds: 1);
      }

      // Sync with Spotify every 10 seconds
      if (_currentPosition.inSeconds % 10 == 0) {
        _updatePlaybackState();
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> _updatePlaybackState() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me/player'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final playerState = jsonDecode(response.body);
        _isPlaying = playerState['is_playing'] ?? false;
        _currentPosition =
            Duration(milliseconds: playerState['progress_ms'] ?? 0);
        _totalDuration =
            Duration(milliseconds: playerState['item']?['duration_ms'] ?? 0);
      }
    } catch (e) {
      _log.warning('Failed to update playback state', e);
    }
  }

  Future<void> playSound(String assetKey) async {
    if (!_isInitialized) {
      throw StateError('AudioController not initialized');
    }

    try {
      final source = await _soloud!.loadAsset(assetKey);
      await _soloud!.play(source);
      _log.fine('Playing sound: $assetKey');
    } catch (e) {
      _log.warning('Failed to play sound: $assetKey', e);
      rethrow;
    }
  }

  Future<void> dispose() async {
    _stopPositionTimer();
    await _recordingController.dispose();
    if (_soloud != null) {
      _soloud!.deinit();
      _soloud = null;
    }
    _isInitialized = false;
    _log.info('Audio system disposed');
  }
}

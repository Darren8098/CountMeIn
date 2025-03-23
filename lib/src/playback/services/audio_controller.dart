import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:count_me_in/src/playback/services/spotify_client.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

class AudioController {
  static final Logger _log = Logger('AudioController');

  final SpotifyClient _spotifyClient;

  AudioController({required SpotifyClient spotifyClient})
    : _spotifyClient = spotifyClient;

  late final PlayerController _playerController;
  SoLoud? _soloud;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _hasActiveDevice = false;

  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get hasActiveDevice => _hasActiveDevice;

  Future<void> initialize() async {
    try {
      _playerController = PlayerController();
      _soloud = SoLoud.instance;
      await _soloud!.init();

      _isInitialized = true;
      _log.info('Audio system initialized successfully');
    } catch (e) {
      _log.severe('Failed to initialize audio system', e);
      rethrow;
    }
  }

  Future<void> startMusic(String trackId, {Duration? startAt}) async {
    if (!_isInitialized) {
      throw StateError('AudioController not initialized');
    }

    try {
      final trackData = await _spotifyClient.getTrackMetadata(trackId);
      _totalDuration = Duration(milliseconds: trackData['duration_ms']);

      await _spotifyClient.startPlayback(trackId, startAt: startAt);

      _currentPosition = startAt ?? Duration.zero;
      _isPlaying = true;
      _startPositionTimer();
      _log.info('Started music playback for track: $trackId');
    } catch (e) {
      _log.severe('Failed to start music playback', e);
      rethrow;
    }
  }

  Future<void> pauseMusic() async {
    if (!_isInitialized) {
      throw StateError('AudioController not initialized');
    }

    if (!_isPlaying) return;

    try {
      _spotifyClient.pausePlayback();
      _isPlaying = false;
      _stopPositionTimer();

      _log.info('Paused music playback');
    } catch (e) {
      _log.warning('Failed to pause music', e);
      rethrow;
    }
  }

  Future<void> resumeMusic() async {
    if (!_isInitialized || _isPlaying) return;

    try {
      _spotifyClient.resumePlayback();
      _isPlaying = true;
      _startPositionTimer();
      _log.info('Resumed music playback');
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

      if (_currentPosition >= _totalDuration) {
        _isPlaying = false;
        _stopPositionTimer();
        _log.info('Track playback completed');
        return;
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
      final playerState = await _spotifyClient.getPlaybackState();

      _isPlaying = playerState['is_playing'] ?? _isPlaying;
      _currentPosition = Duration(
        milliseconds: playerState['progress_ms'] ?? _currentPosition,
      );
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

  Future<void> playLocalFile(String filePath) async {
    if (!_isInitialized) {
      throw StateError('AudioController not initialized');
    }

    try {
      await _playerController.preparePlayer(
        path: filePath,
        shouldExtractWaveform: true,
      );
      _playerController.startPlayer();
      // final source = await _soloud!.loadFile(filePath);
      // await _soloud!.play(source);
      _log.fine('Playing local file: $filePath');
    } catch (e) {
      _log.warning('Failed to play local file: $filePath', e);
      rethrow;
    }
  }

  Future<bool> checkForActiveDevice() async {
    // if (!_isInitialized) {
    //   return;
    // }

    try {
      final devices = await _spotifyClient.getAvailableDevices();
      _log.info('DEVICES: $devices');
      _hasActiveDevice = devices.any((device) => device['is_active'] == true);
      return _hasActiveDevice;
    } catch (e) {
      _log.warning('Error checking for active device', e);
      return false;
    }
  }

  Future<void> openSpotifyApp() async {
    final spotifyUri = Uri.parse('spotify:');
    if (!await launchUrl(spotifyUri)) {
      throw Exception('Could not launch Spotify app');
    }
  }

  Future<void> dispose() async {
    _stopPositionTimer();
    _playerController.dispose();
    if (_soloud != null) {
      _soloud!.deinit();
      _soloud = null;
    }
    _isInitialized = false;
    _log.info('Audio system disposed');
  }
}

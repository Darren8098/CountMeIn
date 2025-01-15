import 'dart:async';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:logging/logging.dart';

class AudioController {
  static final Logger _log = Logger('AudioController');

  SoLoud? _soloud;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      _soloud = SoLoud.instance;
      await _soloud!.init();
      _isInitialized = true;
      _log.info('Audio system initialized successfully');
    } catch (e) {
      _log.severe('Failed to initialize audio system', e);
      rethrow;
    }
  }

  void dispose() {
    try {
      _soloud?.deinit();
      _isInitialized = false;
      _log.info('Audio system disposed');
    } catch (e) {
      _log.warning('Error disposing audio system', e);
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

  Future<void> startMusic(String trackId) async {
    if (!_isInitialized) {
      throw StateError('AudioController not initialized');
    }

    try {
      // TODO: Implement Spotify track playback
      _log.info('Starting music playback for track: $trackId');
    } catch (e) {
      _log.severe('Failed to start music playback', e);
      rethrow;
    }
  }

  void fadeOutMusic() {
    if (!_isInitialized) return;

    try {
      // TODO: Implement fade out
      _log.info('Fading out music');
    } catch (e) {
      _log.warning('Failed to fade out music', e);
    }
  }

  void stopMusic() {
    if (!_isInitialized) return;

    try {
      // TODO: Implement stop
      _log.info('Stopping music');
    } catch (e) {
      _log.warning('Failed to stop music', e);
    }
  }
}

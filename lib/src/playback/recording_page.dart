import 'dart:async';
import 'package:count_me_in/src/playback/audio_controller.dart';
import 'package:count_me_in/src/playback/device_status_widget.dart';
import 'package:count_me_in/src/playback/start_recording_button_widget.dart';
import 'package:count_me_in/src/recording/recording_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bpm_control_widget.dart';
import 'count_in_widget.dart';
import 'playback_controls_widget.dart';
import 'recording_overlay.dart';

class RecordingPage extends StatefulWidget {
  final String trackName;
  final String trackId;
  final AudioController audioController;

  const RecordingPage({
    super.key,
    required this.trackName,
    required this.trackId,
    required this.audioController,
  });

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  double _bpm = 120;
  bool _isPlaying = false;
  bool _isCounting = false;
  int _currentBeat = 0;
  static const int _totalBeats = 4;
  Timer? _progressTimer;
  Duration _position = Duration.zero;
  late final RecordingController _recordingController;
  bool _playbackEnded = false;

  @override
  void initState() {
    super.initState();
    _recordingController = widget.audioController.recordingController;
    _position = widget.audioController.currentPosition;
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          _position = widget.audioController.currentPosition;
        });

        // Check if the song has reached its end
        if (_isPlaying &&
            !_playbackEnded &&
            _position >= widget.audioController.totalDuration) {
          _playbackEnded = true; // Ensure we only run this once

          // Stop the playback UI immediately
          setState(() {
            _isPlaying = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _playCountIn() async {
    if (_isCounting) return;

    setState(() {
      _isCounting = true;
      _currentBeat = 0;
    });

    try {
      final beepDelay = Duration(milliseconds: (60000 / _bpm).round());

      await widget.audioController.startRecording(widget.trackId);

      // Play 4 count-in beats
      for (int i = 1; i <= _totalBeats; i++) {
        await widget.audioController
            .playSound('assets/audio/short-beep-tone.mp3');
        setState(() {
          _currentBeat = i;
        });

        await Future.delayed(beepDelay);
      }

      // Start the track on the next beat
      await Future.delayed(beepDelay);
      await widget.audioController.startMusic(widget.trackId);

      setState(() {
        _isCounting = false;
        _isPlaying = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play audio: $e')),
      );
      setState(() {
        _isCounting = false;
        _currentBeat = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trackName),
      ),
      body: Consumer<AudioController>(
        builder: (context, audioController, child) {
          if (!audioController.hasActiveDevice) {
            return DeviceStatusWidget(
              onDeviceReady: () {},
            );
          }

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    BpmControlWidget(
                      trackName: widget.trackName,
                      bpm: _bpm,
                      onBpmChanged: (value) {
                        setState(() {
                          _bpm = value;
                        });
                      },
                      controlsEnabled: !_isPlaying && !_isCounting,
                    ),
                    const SizedBox(height: 30),
                    if (_isCounting)
                      CountInWidget(
                        currentBeat: _currentBeat,
                        totalBeats: _totalBeats,
                      ),
                    if (_isPlaying)
                      PlaybackControlsWidget(
                        audioController: widget.audioController,
                        currentPosition: _position,
                        totalDuration: widget.audioController.totalDuration,
                        isRecording: _recordingController.isRecording,
                        isPlaying: widget.audioController.isPlaying,
                        onPlayPause: () {
                          if (widget.audioController.isPlaying) {
                            widget.audioController.pauseMusic();
                          } else {
                            widget.audioController.resumeMusic();
                          }
                          setState(() {});
                        },
                        trackId: widget.trackId,
                      ),
                    if (!_isPlaying && !_isCounting)
                      StartRecordingButton(
                        onPressed: _playCountIn,
                      ),
                  ],
                ),
              ),
              if (_recordingController.isRecording) const RecordingOverlay(),
            ],
          );
        },
      ),
    );
  }
}

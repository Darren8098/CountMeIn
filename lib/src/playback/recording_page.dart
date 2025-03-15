import 'dart:async';
import 'package:count_me_in/src/playback/audio_controller.dart';
import 'package:count_me_in/src/playback/device_status_widget.dart';
import 'package:count_me_in/src/recording/recording_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trackName),
      ),
      body: Consumer<AudioController>(
        builder: (context, audioController, child) {
          // Show device status widget if no active device
          if (!audioController.hasActiveDevice) {
            return DeviceStatusWidget(
              onDeviceReady: () {
                if (!audioController.isPlaying) {
                  audioController.startMusic(widget.trackId);
                }
              },
            );
          }

          // Show main recording UI only when we have an active device
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      widget.trackName,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Count-in Speed: ${_bpm.toInt()} BPM',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Slider(
                      value: _bpm,
                      min: 40,
                      max: 240,
                      divisions: 200,
                      label: _bpm.round().toString(),
                      onChanged: _isPlaying || _isCounting
                          ? null
                          : (double value) {
                              setState(() {
                                _bpm = value;
                              });
                            },
                    ),
                    const SizedBox(height: 30),
                    if (_isCounting)
                      Column(
                        children: [
                          Text(
                            '${_currentBeat == 0 ? "Ready" : _currentBeat}',
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                          const SizedBox(height: 20),
                          const CircularProgressIndicator(),
                        ],
                      ),
                    if (_isPlaying)
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_formatDuration(_position)),
                              Expanded(
                                child: widget.audioController.totalDuration.inSeconds >
                                        0
                                    ? Slider(
                                        value: _position.inSeconds.toDouble(),
                                        min: 0,
                                        max: widget.audioController
                                            .totalDuration.inSeconds
                                            .toDouble(),
                                        onChanged: null,
                                      )
                                    : const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                              ),
                              Text(_formatDuration(
                                  widget.audioController.totalDuration)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  widget.audioController.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  size: 48,
                                ),
                                onPressed: () {
                                  if (widget.audioController.isPlaying) {
                                    widget.audioController.pauseMusic();
                                  } else {
                                    widget.audioController.resumeMusic();
                                  }
                                },
                              ),
                              const SizedBox(width: 20),
                              IconButton(
                                icon: Icon(
                                  _recordingController.isRecording
                                      ? Icons.stop_circle
                                      : Icons.fiber_manual_record,
                                  size: 48,
                                  color: _recordingController.isRecording
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                                onPressed: () async {
                                  if (_recordingController.isRecording) {
                                    try {
                                      final saved = await widget.audioController.stopRecording(widget.trackId);
                                      if (saved) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Recording saved successfully!'),
                                              backgroundColor: Colors.green,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to save recording: $e'),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    }
                                  } else {
                                    await widget.audioController.startRecording(widget.trackId);
                                  }
                                  setState(() {}); // Refresh UI
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    if (!_isPlaying && !_isCounting)
                      ElevatedButton.icon(
                        onPressed: _playCountIn,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Recording'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                  ],
                ),
              ),
              if (_recordingController.isRecording)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.red.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fiber_manual_record, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Recording',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _playCountIn() async {
    if (_isCounting) return;

    setState(() {
      _isCounting = true;
      _currentBeat = 0;
    });

    try {
      final beepDelay = Duration(milliseconds: (60000 / _bpm).round());

      // Play 4 count-in beats
      for (int i = 1; i <= _totalBeats; i++) {
        setState(() {
          _currentBeat = i;
        });
        await widget.audioController
            .playSound('assets/audio/short-beep-tone.mp3');
        await Future.delayed(beepDelay);
      }

      // Start the track on the next beat
      await Future.delayed(beepDelay);
      await widget.audioController.startMusic(widget.trackId);
      await widget.audioController.startRecording(widget.trackId);

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
}

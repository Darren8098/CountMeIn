import 'dart:async';

import 'package:count_me_in/src/playback/audio_controller.dart';
import 'package:flutter/material.dart';

class BpmSettingPage extends StatefulWidget {
  final String trackName;
  final String trackId;
  final AudioController audioController;

  const BpmSettingPage({
    super.key,
    required this.trackName,
    required this.trackId,
    required this.audioController,
  });

  @override
  State<BpmSettingPage> createState() => _BpmSettingPageState();
}

class _BpmSettingPageState extends State<BpmSettingPage> {
  double _bpm = 120;
  bool _isPlaying = false;
  bool _isCounting = false;
  int _currentBeat = 0;
  static const int _totalBeats = 4;
  Timer? _progressTimer;

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
        title: Text('Set BPM'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              widget.trackName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Text(
              'BPM: ${_bpm.toInt()}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
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
                  CircularProgressIndicator(),
                ],
              ),
            if (_isPlaying)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_formatDuration(
                          widget.audioController.currentPosition)),
                      Expanded(
                        child: Slider(
                          value: widget
                              .audioController.currentPosition.inMilliseconds
                              .toDouble(),
                          min: 0,
                          max: widget
                              .audioController.totalDuration.inMilliseconds
                              .toDouble(),
                          onChanged: null,
                        ),
                      ),
                      Text(_formatDuration(
                          widget.audioController.totalDuration)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(widget.audioController.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow),
                        onPressed: () {
                          if (widget.audioController.isPlaying) {
                            widget.audioController.pauseMusic();
                          } else {
                            widget.audioController.resumeMusic();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            if (!_isPlaying && !_isCounting)
              ElevatedButton(
                onPressed: _playCountIn,
                child: const Text('Count me in'),
              ),
          ],
        ),
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

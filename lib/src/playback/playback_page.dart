import 'package:count_me_in/src/playback/audio_controller.dart';
import 'package:flutter/material.dart';

class BpmSettingPage extends StatefulWidget {
  final String trackName;

  @override
  State<BpmSettingPage> createState() => _BpmSettingPageState();

  const BpmSettingPage(
      {super.key, required this.trackName, required this.audioController});

  final AudioController audioController;
}

class _BpmSettingPageState extends State<BpmSettingPage> {
  double _bpm = 120;
  bool _isPlaying = false;
  int _currentBeat = 0;
  static const int _totalBeats = 4; // Standard 4-beat count-in

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
              onChanged: _isPlaying
                  ? null
                  : (double value) {
                      setState(() {
                        _bpm = value;
                      });
                    },
            ),
            const SizedBox(height: 30),
            if (_isPlaying)
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
            if (!_isPlaying)
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
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
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

      // TODO: Start playing the actual track here
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play audio: $e')),
      );
    } finally {
      setState(() {
        _isPlaying = false;
        _currentBeat = 0;
      });
    }
  }
}

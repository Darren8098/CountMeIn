import 'package:count_me_in/src/recordings/services/recording_controller.dart';
import 'package:flutter/material.dart';
import 'package:count_me_in/src/playback/services/audio_controller.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class PlaybackControlsWidget extends StatelessWidget {
  final AudioController audioController;
  final RecordingController recordingController;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isRecording;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final String trackId;

  const PlaybackControlsWidget({
    super.key,
    required this.audioController,
    required this.recordingController,
    required this.currentPosition,
    required this.totalDuration,
    required this.isRecording,
    required this.isPlaying,
    required this.onPlayPause,
    required this.trackId,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(_formatDuration(currentPosition)),
            Expanded(
              child:
                  totalDuration.inSeconds > 0
                      ? AudioWaveforms(
                        recorderController:
                            recordingController.recorderController,
                        size: Size(MediaQuery.of(context).size.width, 50),
                        enableGesture: true,
                        waveStyle: WaveStyle(
                          // showTop: true,
                          // showBottom: true,
                          // showDurationLabel: true,
                          extendWaveform: true,
                        ),
                      )
                      : const Center(child: CircularProgressIndicator()),
            ),
            Text(_formatDuration(totalDuration)),
          ],
        ),
        const SizedBox(height: 20),
        // Control buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: 48,
              ),
              onPressed: onPlayPause,
            ),
            const SizedBox(width: 20),
          ],
        ),
      ],
    );
  }
}

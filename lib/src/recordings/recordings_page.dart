import 'package:count_me_in/src/playback/services/audio_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:count_me_in/src/recordings/recording.dart';
import 'package:count_me_in/src/recordings/services/recordings_repository.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class RecordingsPage extends StatelessWidget {
  const RecordingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordingsRepository>(
      builder: (context, recordingService, child) {
        final recordings = recordingService.recordings;

        if (recordings.isEmpty) {
          return const Center(
            child: Text(
              'No recordings yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: recordings.length,
          itemBuilder: (context, index) {
            final recording = recordings[index];
            return ListTile(
              title: Text(recording.trackName),
              subtitle: Text(
                DateFormat('MMM d, y h:mm a').format(recording.recordedAt),
              ),
              leading: const Icon(Icons.music_note),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => _handlePlayRecording(context, recording),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () =>
                        recordingService.deleteRecording(recording.id),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handlePlayRecording(
      BuildContext context, Recording recording) async {
    try {
      final file = File(recording.filePath);
      if (!await file.exists() && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording file not found')),
        );
        return;
      }

      final audioController = context.read<AudioController>();
      await audioController.playLocalFile(recording.filePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playing ${recording.trackName}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to play recording: ${e.toString()}')));
      }
    }
  }
}

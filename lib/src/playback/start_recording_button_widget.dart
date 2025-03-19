import 'package:flutter/material.dart';

class StartRecordingButton extends StatelessWidget {
  final VoidCallback onPressed;

  const StartRecordingButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.play_arrow),
      label: const Text('Start Recording'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}

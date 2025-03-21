import 'package:flutter/material.dart';

class CountInWidget extends StatelessWidget {
  final int currentBeat;
  final int totalBeats;

  const CountInWidget({
    super.key,
    required this.currentBeat,
    required this.totalBeats,
  });

  @override
  Widget build(BuildContext context) {
    String displayText = currentBeat == 0 ? 'Ready' : '$currentBeat';
    return Column(
      children: [
        Text(
          displayText,
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 20),
        const CircularProgressIndicator(),
      ],
    );
  }
}

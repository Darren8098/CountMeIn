import 'package:flutter/material.dart';

class BpmControlWidget extends StatelessWidget {
  final String trackName;
  final double bpm;
  final ValueChanged<double> onBpmChanged;
  final bool controlsEnabled;

  const BpmControlWidget({
    super.key,
    required this.trackName,
    required this.bpm,
    required this.onBpmChanged,
    this.controlsEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          trackName,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          'Count-in Speed: ${bpm.toInt()} BPM',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Slider(
          value: bpm,
          min: 40,
          max: 240,
          divisions: 200,
          label: bpm.round().toString(),
          onChanged: controlsEnabled ? onBpmChanged : null,
        ),
      ],
    );
  }
}

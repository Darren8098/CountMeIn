import 'package:flutter/material.dart';

class RecordingOverlay extends StatelessWidget {
  const RecordingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          color: Colors.red.withAlpha(Color.getAlphaFromOpacity(0.8)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fiber_manual_record, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Recording',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

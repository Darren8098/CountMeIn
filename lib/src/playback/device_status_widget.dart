import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:count_me_in/src/playback/audio_controller.dart';

class DeviceStatusWidget extends StatefulWidget {
  final VoidCallback? onDeviceReady;

  const DeviceStatusWidget({super.key, this.onDeviceReady});

  @override
  State<DeviceStatusWidget> createState() => _DeviceStatusWidgetState();
}

class _DeviceStatusWidgetState extends State<DeviceStatusWidget> {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkDeviceStatus();
  }

  Future<void> _checkDeviceStatus() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      final audioController = context.read<AudioController>();
      final hasDevice = await audioController.checkForActiveDevice();
      
      if (hasDevice && widget.onDeviceReady != null) {
        widget.onDeviceReady!();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioController>(
      builder: (context, audioController, child) {
        if (_isChecking) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (audioController.hasActiveDevice) {
          return const SizedBox.shrink(); // Hide when device is active
        }

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No active Spotify device found',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await audioController.openSpotifyApp();
                    // Wait a bit for Spotify to start
                    await Future.delayed(const Duration(seconds: 2));
                    if (mounted) {
                      await _checkDeviceStatus();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to open Spotify app. Please open it manually.'),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Open Spotify App'),
              ),
              if (!_isChecking) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _checkDeviceStatus,
                  child: const Text('Check Again'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

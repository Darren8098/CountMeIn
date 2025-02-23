import 'dart:developer' as dev;

import 'package:count_me_in/src/auth/login_page.dart';
import 'package:count_me_in/src/playback/audio_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:count_me_in/src/auth/auth_service.dart';
import 'package:count_me_in/src/navigation/home_page.dart';
import 'package:count_me_in/src/recording/recording_service.dart';

void main() async {
  const String spotifyApiBaseUrl = 'https://api.spotify.com/v1';
  
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    dev.log(
      '${record.level.name}: ${record.time}: ${record.message}',
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      zone: record.zone,
      error: record.error,
      stackTrace: record.stackTrace,
    );
    if (record.error != null) {
      dev.log('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      dev.log('Stack trace:\n${record.stackTrace}');
    }
  });


  WidgetsFlutterBinding.ensureInitialized();

  final recordingService = RecordingService();
  await recordingService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RecordingService>(
          create: (_) => recordingService,
        ),
        Provider<AudioController>(
          create: (context) => AudioController(
            spotifyApiBaseUrl,
            recordingService: context.read<RecordingService>(),
          ),
          dispose: (_, controller) => controller.dispose(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Count Me In',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

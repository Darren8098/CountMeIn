import 'dart:developer' as dev;

import 'package:count_me_in/src/auth/login_page.dart';
import 'package:count_me_in/src/playback/audio_controller.dart';
import 'package:count_me_in/src/playback/spotify_client.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:count_me_in/src/recording/recordings_repository.dart';

void main() async {
  const String spotifyApiBaseUrl = 'https://api.spotify.com/v1';
  const String spotifyAuthBaseUrl = 'accounts.spotify.com';

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

  final recordingRepository = RecordingsRepository();
  await recordingRepository.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RecordingsRepository>.value(
            value: recordingRepository),
        Provider<SpotifyClient>(
            create: (_) =>
                SpotifyClient(spotifyApiBaseUrl, spotifyAuthBaseUrl)),
        ProxyProvider<SpotifyClient, AudioController>(
          update: (context, spotifyClient, __) => AudioController(
              recordingService: context.read<RecordingsRepository>(),
              spotifyClient: spotifyClient),
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

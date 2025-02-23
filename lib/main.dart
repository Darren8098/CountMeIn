import 'dart:developer' as dev;

import 'package:count_me_in/src/auth/login_page.dart';
import 'package:count_me_in/src/playback/audio_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

void main() async {
  const String spotifyApiBaseUrl = 'https://api.spotify.com/v1';
  
  Logger.root.level = kDebugMode ? Level.FINE : Level.INFO;
  Logger.root.onRecord.listen((record) {
    dev.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      zone: record.zone,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });


  WidgetsFlutterBinding.ensureInitialized();

  final audioController = AudioController(spotifyApiBaseUrl);

  runApp(MultiProvider(providers: [
    Provider(create: (_) => audioController),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Count Me In',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}

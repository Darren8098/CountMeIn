import 'package:count_me_in/src/playback/services/audio_controller.dart';
import 'package:count_me_in/src/playback/services/spotify_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:count_me_in/src/navigation/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final spotifyClient = Provider.of<SpotifyClient>(context, listen: false);
    final success = await spotifyClient.authenticate();

    if (success && mounted) {
      final audioController =
          Provider.of<AudioController>(context, listen: false);
      await audioController.initialize();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Count Me In'),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _handleLogin,
                child: Text('Login with Spotify'),
              ),
      ),
    );
  }
}

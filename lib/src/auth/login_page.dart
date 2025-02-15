import 'package:count_me_in/src/search/search_page.dart';
import 'package:count_me_in/src/playback/audio_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final token = await _authService.authenticate();

    if (token != null) {
      // Initialize audio controller with the token
      final audioController = Provider.of<AudioController>(context, listen: false);
      audioController.setAccessToken(token);
      await audioController.initialize();

      // Navigate to search page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SearchPage(accessToken: token),
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

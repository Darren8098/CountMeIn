import 'package:count_me_in/src/search/search_page.dart';
import 'package:flutter/material.dart';
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

    print("TOKEN: ${token}");
    setState(() {
      _isLoading = false;
    });

    if (token != null) {
      // Navigate to search page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SearchPage(accessToken: token),
        ),
      );
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

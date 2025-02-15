import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// TODO here for testing move this to backend or use PKCE
const String clientId = '{CLIENT_ID}';
const String clientSecret = '{CLIENT_SECRET}';
const String redirectUri = 'countmein://callback';

final String scopes =
    'user-read-private user-read-playback-state user-modify-playback-state user-read-currently-playing';

String _buildAuthUrl() {
  // TODO add state parameter
  return Uri.https('accounts.spotify.com', '/authorize', {
    'client_id': clientId,
    'response_type': 'code',
    'redirect_uri': redirectUri,
    'scope': scopes,
    'show_dialog': 'true',
  }).toString();
}

class AuthService {
  Future<String?> authenticate() async {
    try {
      final authUrl = _buildAuthUrl();

      // Open the browser for user login
      final result = await FlutterWebAuth2.authenticate(
          url: authUrl, callbackUrlScheme: 'countmein');

      // "result" will look like: myapp://callback?code=<AUTH_CODE>
      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];

      print("AUTH RESPONSE URI: $uri");
      print("AUTH RESPONSE CODE: $code");
      if (code == null) {
        return null;
      }

      // Exchange code for access token
      final token = await _getAccessToken(code);
      return token;
    } catch (e) {
      print('Authentication error: $e');
      return null;
    }
  }

  Future<String?> _getAccessToken(String code) async {
    final uri = Uri.parse('https://accounts.spotify.com/api/token');

    final response = await http.post(uri, headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization':
          'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}'
    }, body: {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': redirectUri
    });

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['access_token'];
    } else {
      print('Token request failed: ${response.body}');
      return null;
    }
  }
}

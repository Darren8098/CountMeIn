import 'dart:async';
import 'dart:convert';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class SpotifyClient {
  static final Logger _log = Logger('SpotifyClient');

  final String authBaseUrl;
  final String apiBaseUrl;
  String? _accessToken;
  String? _deviceId;

  static const String clientId = '{CLIENT_ID}';
  static const String clientSecret = '{CLIENT_SECRET}';
  static const String redirectUri = 'countmein://callback';
  static const String scopes =
      'user-read-private user-read-playback-state user-modify-playback-state user-read-currently-playing';

  SpotifyClient(this.apiBaseUrl, this.authBaseUrl);

  void setAccessToken(String token) {
    _accessToken = token;
  }

  String? get deviceId => _deviceId;

  Future<bool> authenticate() async {
    try {
      final authUrl = _buildAuthUrl();

      // Open the browser for user login
      final result = await FlutterWebAuth2.authenticate(
          url: authUrl, callbackUrlScheme: 'countmein');

      // Parse the authorization code from the callback URL
      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];

      if (code == null) {
        _log.warning('No authorization code returned');
        return false;
      }

      // Exchange the code for an access token
      final token = await _getAccessToken(code);
      if (token != null) {
        setAccessToken(token);
        return true;
      }

      return false;
    } catch (e) {
      _log.severe('Authentication error', e);
      return false;
    }
  }

  String _buildAuthUrl() {
    return Uri.https(authBaseUrl, '/authorize', {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'scope': scopes,
      'show_dialog': 'true',
    }).toString();
  }

  Future<String?> _getAccessToken(String code) async {
    final uri = Uri.https(authBaseUrl, '/api/token');

    try {
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
        _log.warning(
            'Token request failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      _log.severe('Error getting access token', e);
      return null;
    }
  }

  Future<Map<String, dynamic>> getTrackMetadata(String trackId) async {
    _validateToken();

    final response = await http.get(
      Uri.parse('$apiBaseUrl/tracks/$trackId'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      _log.warning(
          'Failed to get track metadata: ${response.statusCode}, "${response.body}"');
      throw Exception('Failed to get track metadata: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableDevices() async {
    _validateToken();

    final response = await http.get(
      Uri.parse('$apiBaseUrl/me/player/devices'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      final devices = jsonDecode(response.body)['devices'] as List;
      if (devices.isNotEmpty) {
        _deviceId = devices.firstWhere((device) => device['is_active'])['id'];
      }
      return List<Map<String, dynamic>>.from(devices);
    } else {
      throw Exception(
          'Failed to get available devices: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> startPlayback(String trackId, {Duration? startAt}) async {
    _validateToken();

    final response = await http.put(
      Uri.parse(
          '$apiBaseUrl/me/player/play${_deviceId != null ? '?device_id=$_deviceId' : ''}'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'uris': ['spotify:track:$trackId'],
        'position_ms': startAt?.inMilliseconds ?? 0,
      }),
    );

    if (response.statusCode != 204) {
      throw Exception(
          'Failed to start playback: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> pausePlayback() async {
    _validateToken();

    final response = await http.put(
      Uri.parse('$apiBaseUrl/me/player/pause'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to pause playback: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> resumePlayback() async {
    _validateToken();

    final response = await http.put(
      Uri.parse(
          '$apiBaseUrl/me/player/play${_deviceId != null ? '?device_id=$_deviceId' : ''}'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to resume playback: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getPlaybackState() async {
    _validateToken();

    final response = await http.get(
      Uri.parse('$apiBaseUrl/me/player'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to get playback state: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> searchTracks(String query,
      {int limit = 10}) async {
    _validateToken();

    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/search?q=$query&type=track&limit=$limit'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(
            data['tracks']['items'].map((item) => {
                  'id': item['id'],
                  'name': item['name'],
                  'artist': item['artists'][0]['name'],
                  'albumArt': item['album']['images'].isNotEmpty
                      ? item['album']['images'][0]['url']
                      : null,
                }));
      } else {
        _log.warning(
            'Search failed: ${response.statusCode}, "${response.body}"');
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      _log.severe('Error searching tracks', e);
      throw Exception('Error searching tracks: $e');
    }
  }

  void _validateToken() {
    if (_accessToken == null) {
      throw StateError('Access token not set');
    }
  }
}

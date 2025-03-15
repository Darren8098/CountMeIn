import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class SpotifyClient {
  static final Logger _log = Logger('SpotifyClient');

  final String baseUrl;
  String? _accessToken;
  String? _deviceId;

  SpotifyClient(this.baseUrl);

  void setAccessToken(String token) {
    _accessToken = token;
  }

  String? get deviceId => _deviceId;

  Future<Map<String, dynamic>> getTrackMetadata(String trackId) async {
    _validateToken();

    final response = await http.get(
      Uri.parse('$baseUrl/tracks/$trackId'),
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
      Uri.parse('$baseUrl/me/player/devices'),
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
          '$baseUrl/me/player/play${_deviceId != null ? '?device_id=$_deviceId' : ''}'),
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
      Uri.parse('$baseUrl/me/player/pause'),
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
          '$baseUrl/me/player/play${_deviceId != null ? '?device_id=$_deviceId' : ''}'),
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
      Uri.parse('$baseUrl/me/player'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to get playback state: ${response.statusCode} ${response.body}');
    }
  }

  void _validateToken() {
    if (_accessToken == null) {
      throw StateError('Access token not set');
    }
  }
}

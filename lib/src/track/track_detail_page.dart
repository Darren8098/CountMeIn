import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TrackDetailPage extends StatefulWidget {
  final String accessToken;
  final String trackId;

  const TrackDetailPage({
    super.key,
    required this.accessToken,
    required this.trackId,
  });

  @override
  State<TrackDetailPage> createState() => _TrackDetailPageState();
}

class _TrackDetailPageState extends State<TrackDetailPage> {
  double? tempo;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTempo();
  }

  Future<void> _fetchTempo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final url = Uri.parse(
        'https://api.spotify.com/v1/audio-features/${widget.trackId}');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.accessToken}',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      setState(() {
        tempo = jsonResponse['tempo']?.toDouble();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _error = 'Error fetching tempo: ${response.body}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Track Tempo')),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : _error != null
                ? Text(_error!)
                : tempo != null
                    ? Text('Tempo: $tempo BPM')
                    : Text('No tempo info'),
      ),
    );
  }
}

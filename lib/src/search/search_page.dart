import 'dart:convert';

import 'package:count_me_in/src/playback/audio_controller.dart';
import 'package:count_me_in/src/playback/playback_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  final String accessToken;
  final String baseUrl;

  const SearchPage({super.key, required this.accessToken, required this.baseUrl});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _trackResults = [];

  Future<void> _searchTracks(String query) async {
    final url = Uri.https(widget.baseUrl, '/v1/search', {
      'q': query,
      'type': 'track',
      'limit': '10',
    });

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.accessToken}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final tracks = jsonResponse['tracks']['items'] as List;

      setState(() {
        _trackResults = tracks.map((track) {
          return {
            'id': track['id'],
            'name': track['name'],
            'artist': (track['artists'] as List).isNotEmpty
                ? track['artists'][0]['name']
                : 'Unknown',
          };
        }).toList();
      });
    } else {
      print('Search failed: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search a Track')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for a track',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _searchTracks(_searchController.text),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _trackResults.length,
                itemBuilder: (context, index) {
                  final track = _trackResults[index];
                  return ListTile(
                    title: Text(track['name']),
                    subtitle: Text(track['artist']),
                    onTap: () {
                      final audioController = context.read<AudioController>();
                      audioController.setAccessToken(widget.accessToken);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BpmSettingPage(
                            trackName: track['name'],
                            trackId: track['id'],
                            audioController: audioController,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

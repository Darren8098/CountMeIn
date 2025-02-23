import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:count_me_in/src/playback/audio_controller.dart';
import 'package:count_me_in/src/playback/recording_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchAndPlaybackPage extends StatefulWidget {
  final String accessToken;
  final String baseUrl;

  const SearchAndPlaybackPage({
    super.key,
    required this.accessToken,
    required this.baseUrl,
  });

  @override
  State<SearchAndPlaybackPage> createState() => _SearchAndPlaybackPageState();
}

class _SearchAndPlaybackPageState extends State<SearchAndPlaybackPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounceTimer;
  bool _isLoading = false;
  String? _selectedTrackId;
  String? _selectedTrackName;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/search?q=$query&type=track&limit=5'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(
              data['tracks']['items'].map((item) => {
                    'id': item['id'],
                    'name': item['name'],
                    'artist': item['artists'][0]['name'],
                    'albumArt': item['album']['images'].isNotEmpty
                        ? item['album']['images'][0]['url']
                        : null,
                  }));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTrackSelected(String trackId, String trackName) {
    setState(() {
      _selectedTrackId = trackId;
      _selectedTrackName = trackName;
      _searchResults = [];
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record a Track'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a song to record with...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                });
                              },
                            )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (_searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      leading: result['albumArt'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                result['albumArt'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.music_note, size: 50),
                      title: Text(result['name']),
                      subtitle: Text(result['artist']),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _onTrackSelected(
                        result['id'],
                        result['name'],
                      ),
                    );
                  },
                ),
              ),
            if (_selectedTrackId != null && _selectedTrackName != null)
              Expanded(
                child: RecordingPage(
                  trackId: _selectedTrackId!,
                  trackName: _selectedTrackName!,
                  audioController: context.read<AudioController>(),
                ),
              ),
            if (_searchResults.isEmpty && _selectedTrackId == null)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Search for a song to get started!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      Text(
                        'You can record yourself playing along',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

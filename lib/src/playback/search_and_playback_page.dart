import 'dart:async';
import 'package:count_me_in/src/playback/services/spotify_client.dart';
import 'package:count_me_in/src/recordings/services/recording_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:count_me_in/src/playback/services/audio_controller.dart';
import 'package:count_me_in/src/playback/recording_page.dart';

class SearchAndPlaybackPage extends StatefulWidget {
  const SearchAndPlaybackPage({
    super.key,
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
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final spotifyClient = Provider.of<SpotifyClient>(context, listen: false);
      final results = await spotifyClient.searchTracks(query, limit: 5);

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
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
                  recordingController: context.read<RecordingController>(),
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

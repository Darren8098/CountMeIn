import 'package:flutter/material.dart';
import 'package:count_me_in/src/search/search_page.dart';
import 'package:count_me_in/src/recording/recordings_page.dart';

class HomePage extends StatefulWidget {
  final String accessToken;
  final String baseUrl;

  const HomePage({
    super.key,
    required this.accessToken,
    required this.baseUrl,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      SearchPage(
        accessToken: widget.accessToken,
        baseUrl: widget.baseUrl,
      ),
      const RecordingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Recordings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

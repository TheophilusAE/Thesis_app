import 'package:flutter/material.dart';

import 'remake_bible_screen.dart';

class RemakeShellScreen extends StatefulWidget {
  const RemakeShellScreen({super.key});

  @override
  State<RemakeShellScreen> createState() => _RemakeShellScreenState();
}

class _RemakeShellScreenState extends State<RemakeShellScreen> {
  int _index = 0;

  static const _titles = [
    'Dashboard',
    'Alkitab XML',
    'Settings',
  ];

  final _pages = const [
    _DashboardPage(),
    RemakeBibleScreen(),
    _SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Bible'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gereja App Remake',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This app has been rebuilt from scratch with a clean shell and XML-first Bible reading.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings placeholder for remake phase 1.'),
    );
  }
}

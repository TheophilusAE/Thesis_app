import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/devotional_service.dart';
import '../models/devotional.dart';
import 'bible_screen.dart';
import 'profile_screen.dart';
import 'member_card_screen.dart';
import 'qr_scanner_screen.dart';
import 'quest_screen.dart';
import 'devotional_screen.dart';
import 'playlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const BibleScreen(),
    const QuestScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Alkitab',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Quest',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QRScannerScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          child: Text(
                            authProvider.currentUser?.name[0] ?? 'U',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat Datang,',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                authProvider.currentUser?.name ?? 'User',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Quick Access Grid
            Text(
              'Fitur Utama',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _FeatureCard(
                  icon: Icons.card_membership,
                  title: 'Kartu Jemaat',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MemberCardScreen()),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.book,
                  title: 'Alkitab',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BibleScreen()),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.task_alt,
                  title: 'Quest Baca',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QuestScreen()),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.menu_book,
                  title: 'Renungan',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DevotionalScreen()),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.music_note,
                  title: 'Playlist Hari Ini',
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PlaylistScreen()),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.qr_code_scanner,
                  title: 'Scan Event',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Today's Devotional Preview
            Text(
              'Renungan Hari Ini',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Devotional>(
              future: DevotionalService().getTodaysDevotional(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final devotional = snapshot.data!;
                  return Card(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DevotionalScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              devotional.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              devotional.verseReference,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              devotional.content.substring(
                                0,
                                devotional.content.length > 100
                                    ? 100
                                    : devotional.content.length,
                              ) + '...',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Baca selengkapnya →',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

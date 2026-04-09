import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/devotional_service.dart';
import '../models/devotional.dart';
import '../utils/app_theme.dart';
import 'bible_screen.dart';
import 'profile_screen.dart';
import 'member_card_screen.dart';
import 'qr_scanner_screen.dart';
import 'quest_screen.dart';
import 'devotional_screen.dart';
import 'playlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Alkitab'),
          BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Quest'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  void _showNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Belum ada notifikasi baru.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openQuickSearch(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final actions = [
          (
            title: 'Alkitab',
            icon: Icons.book,
            pageBuilder: () => const BibleScreen(),
          ),
          (
            title: 'Quest',
            icon: Icons.task_alt,
            pageBuilder: () => const QuestScreen(),
          ),
          (
            title: 'Renungan',
            icon: Icons.menu_book,
            pageBuilder: () => const DevotionalScreen(),
          ),
          (
            title: 'Playlist',
            icon: Icons.music_note,
            pageBuilder: () => const PlaylistScreen(),
          ),
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih fitur cepat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ...actions.map(
                  (action) => ListTile(
                    leading: Icon(action.icon),
                    title: Text(action.title),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => action.pageBuilder()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.currentUser;
                return Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                          child: Text(
                            user?.name.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Halo', style: textTheme.bodySmall),
                              Text(
                                user?.name ?? 'Anggota',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_none_rounded),
                            tooltip: 'Notifikasi',
                            onPressed: () => _showNotifications(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _openQuickSearch(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Cari fitur, renungan, playlist',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.tune_rounded, color: Color(0xFF94A3B8)),
                                tooltip: 'Filter fitur',
                                onPressed: () => _openQuickSearch(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            _HomeImageCarousel(
              onOpenMemberCard: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MemberCardScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            Text(
              'Fitur Utama',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 0.72,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _FeatureCard(
                  icon: Icons.card_membership,
                  title: 'Kartu Jemaat',
                   gradient: AppTheme.blueGradient,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MemberCardScreen(),
                      ),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.book,
                  title: 'Alkitab',
                   gradient: AppTheme.purpleGradient,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BibleScreen(),
                      ),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.task_alt,
                  title: 'Quest Baca',
                   gradient: AppTheme.cyanGradient,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuestScreen(),
                      ),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.menu_book,
                  title: 'Renungan',
                   gradient: LinearGradient(
                     colors: [Color(0xFF66B68D), Color(0xFF4FA77A)],
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                   ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DevotionalScreen(),
                      ),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.music_note,
                  title: 'Playlist Hari Ini',
                   gradient: LinearGradient(
                     colors: [Color(0xFF8FCEA9), Color(0xFF64B48B)],
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                   ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlaylistScreen(),
                      ),
                    );
                  },
                ),
                _FeatureCard(
                  icon: Icons.qr_code_scanner,
                  title: 'Event/Ibadah',
                   gradient: LinearGradient(
                     colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                   ),
                  onTap: () {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final user = authProvider.currentUser;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QRScannerScreen(
                          memberId: user?.memberCardNumber ?? user?.id ?? 'UNKNOWN',
                          memberName: user?.name ?? 'Anggota Gereja',
                          isAdminMode: authProvider.isAdmin,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Today's Devotional Preview
            Text(
              'Renungan Hari Ini',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            FutureBuilder<Devotional>(
              future: DevotionalService().getTodaysDevotional(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final devotional = snapshot.data!;
                  return Container(
                    decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(20),
                       gradient: AppTheme.purpleGradient,
                      boxShadow: [
                        BoxShadow(
                           color: const Color(0xFF58A77E).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DevotionalScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      devotional.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.bookmark_border,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  devotional.verseReference,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${devotional.content.substring(
                                  0,
                                  devotional.content.length > 100
                                      ? 100
                                      : devotional.content.length,
                                )}...',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
                                      height: 1.5,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Baca selengkapnya ',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ],
                          ),
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
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _HomeImageCarousel extends StatefulWidget {
  final VoidCallback onOpenMemberCard;

  const _HomeImageCarousel({required this.onOpenMemberCard});

  @override
  State<_HomeImageCarousel> createState() => _HomeImageCarouselState();
}

class _HomeImageCarouselState extends State<_HomeImageCarousel> {
  final PageController _pageController = PageController(viewportFraction: 1);
  Timer? _timer;
  int _currentPage = 0;

  final List<String> _images = const [
    'assets/images/carousel_1.jpg',
    'assets/images/carousel_2.jpg',
    'assets/images/carousel_3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      final nextPage = (_currentPage + 1) % _images.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 194,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      _images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.purpleBlueGradient,
                          ),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.black.withValues(alpha: 0.26),
                            Colors.black.withValues(alpha: 0.44),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kartu Jemaat Digital',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Akses identitas jemaat dan QR kehadiran dalam satu kartu.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.92),
                                      ),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton(
                                  onPressed: widget.onOpenMemberCard,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF4B9A72),
                                    minimumSize: const Size(0, 40),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: const Text('Buka Kartu'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _images.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 20 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFF4B9A72)
                    : const Color(0xFFBFD9CB),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureCardState extends State<_FeatureCard> {
  bool? _isHovered;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
         borderRadius: BorderRadius.circular(20),
         gradient: widget.gradient,
          boxShadow: [
            BoxShadow(
             color: const Color(0xFF58A77E).withValues(alpha: 0.3),
              blurRadius: _isHovered == true ? 12 : 6,
              offset: Offset(0, _isHovered == true ? -2 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, size: 34, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

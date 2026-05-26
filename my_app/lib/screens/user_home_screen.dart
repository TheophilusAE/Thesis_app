import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/devotional_service.dart';
import '../models/devotional.dart';
import '../utils/app_theme.dart';
import '../widgets/role_switcher.dart';
import 'bible_screen.dart';
import 'profile_screen.dart';
import 'member_card_screen.dart';
import 'qr_scanner_screen.dart';
import 'quest_screen.dart';
import 'devotional_screen.dart';
import 'playlist_screen.dart';
import 'feedback_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const UserHomeTab(),
      const BibleScreen(),
      const QuestScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
            ),
          ),
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              if (authProvider.userRoles.length > 1) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: RoleSwitcher(),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
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

class UserHomeTab extends StatelessWidget {
  const UserHomeTab({super.key});

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
                            backgroundColor:
                                colorScheme.primary.withValues(alpha: 0.12),
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
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0)),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                  Icons.notifications_none_rounded),
                              tooltip: 'Notifikasi',
                              onPressed: () =>
                                  _showNotifications(context),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded,
                                    color: Color(0xFF94A3B8)),
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
                                  icon: const Icon(Icons.tune_rounded,
                                      color: Color(0xFF94A3B8)),
                                  tooltip: 'Filter fitur',
                                  onPressed: () =>
                                      _openQuickSearch(context),
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
                style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700),
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
                          builder: (context) =>
                              const MemberCardScreen(),
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
                      colors: const [Color(0xFF66B68D), Color(0xFF4FA77A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DevotionalScreen(),
                        ),
                      );
                    },
                  ),
                  _FeatureCard(
                    icon: Icons.music_note,
                    title: 'Playlist Hari Ini',
                    gradient: LinearGradient(
                      colors: const [
                        Color(0xFF8FCEA9),
                        Color(0xFF64B48B)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PlaylistScreen(),
                        ),
                      );
                    },
                  ),
                  _FeatureCard(
                    icon: Icons.feedback,
                    title: 'Feedback',
                    gradient: LinearGradient(
                      colors: const [
                        Color(0xFFF97316),
                        Color(0xFFEA580C)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        builder: (sheetContext) {
                          return SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pilih Tipe Feedback',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  ListTile(
                                    leading:
                                        const Icon(Icons.event),
                                    title: const Text(
                                        'Feedback Event'),
                                    subtitle: const Text(
                                        'Bagikan pengalaman event'),
                                    trailing: const Icon(
                                        Icons.chevron_right),
                                    onTap: () {
                                      Navigator.pop(sheetContext);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const FeedbackScreen(
                                                feedbackType:
                                                    'event',
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading:
                                        const Icon(Icons.home),
                                    title: const Text(
                                        'Feedback Fasilitas'),
                                    subtitle: const Text(
                                        'Saran untuk fasilitas gereja'),
                                    trailing: const Icon(
                                        Icons.chevron_right),
                                    onTap: () {
                                      Navigator.pop(sheetContext);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const FeedbackScreen(
                                                feedbackType:
                                                    'facility',
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading:
                                        const Icon(Icons.people),
                                    title: const Text(
                                        'Feedback Hospitality'),
                                    subtitle: const Text(
                                        'Pengalaman layanan hospitality'),
                                    trailing: const Icon(
                                        Icons.chevron_right),
                                    onTap: () {
                                      Navigator.pop(sheetContext);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const FeedbackScreen(
                                                feedbackType:
                                                    'hospitality',
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Renungan Hari Ini',
                style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700),
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
                            color:
                                const Color(0xFF58A77E)
                                    .withValues(alpha: 0.35),
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
                                builder: (context) =>
                                    const DevotionalScreen(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        devotional.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight:
                                                  FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                        maxLines: 2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.2),
                                        borderRadius:
                                            BorderRadius.circular(
                                                8),
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
                                  padding: const EdgeInsets
                                      .symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha: 0.2),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    devotional.verseReference,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.white,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  devotional.content,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        height: 1.5,
                                      ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: AppTheme.purpleGradient,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<
                              Color>(Colors.white)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeImageCarousel extends StatelessWidget {
  final VoidCallback onOpenMemberCard;

  const _HomeImageCarousel({required this.onOpenMemberCard});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: const [Color(0xFF58A77E), Color(0xFF3F8F5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onOpenMemberCard,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Kartu Anggota Digital',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tunjukkan kartu anggota digital Anda',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onOpenMemberCard,
                  icon: const Icon(Icons.card_membership),
                  label: const Text('Buka Kartu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF58A77E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Gradient gradient;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

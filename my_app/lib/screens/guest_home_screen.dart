import 'package:flutter/material.dart';

import '../models/public_service.dart';
import '../widgets/common/compact_feature_tile.dart';
import '../widgets/login_required.dart';
import 'bible_screen.dart';
import 'devotional_screen.dart';
import 'event_list_screen.dart';
import 'public_schedule_screen.dart';
import 'sermon_library_screen.dart';

/// Home for visitors who have not signed in (guest mode).
///
/// Only public information is shown: worship times (without pelayan
/// names), events, devotionals, sermons and the offline Bible. Everything
/// personal asks the visitor to sign in. The database enforces the same
/// boundary: the `anon` role can read only these public tables/RPCs.
class GuestHomeScreen extends StatefulWidget {
  /// Injectable for tests; defaults to the app-wide Supabase gateway.
  final Future<List<PublicServiceSlot>> Function(DateTime from, DateTime to)? scheduleLoader;

  const GuestHomeScreen({super.key, this.scheduleLoader});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  int _index = 0;
  late Future<List<PublicServiceSlot>> _schedule;

  @override
  void initState() {
    super.initState();
    _schedule = _loadSchedule();
  }

  Future<List<PublicServiceSlot>> _loadSchedule() {
    final today = DateTime.now();
    final from = DateTime(today.year, today.month, today.day);
    final to = from.add(const Duration(days: 30));
    return (widget.scheduleLoader ?? loadPublicSchedule)(from, to);
  }

  Future<void> _refresh() async {
    setState(() => _schedule = _loadSchedule());
    await _schedule.catchError((_) => <PublicServiceSlot>[]);
  }

  /// Only the visible tab is built (the Bible reader is heavy and opens its
  /// local database on first build).
  Widget _page() {
    switch (_index) {
      case 1:
        return PublicScheduleView(schedule: _schedule, onRefresh: _refresh);
      case 2:
        return const BibleScreen();
      case 3:
        return const _GuestAccountTab();
      default:
        return _GuestBeranda(
          schedule: _schedule,
          onRefresh: _refresh,
          onOpenSchedule: () => setState(() => _index = 1),
          onOpenBible: () => setState(() => _index = 2),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: _page()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note_rounded), label: 'Jadwal'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Alkitab'),
          NavigationDestination(icon: Icon(Icons.login_rounded), label: 'Masuk'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Beranda
// ─────────────────────────────────────────────────────────────────────────────

class _GuestBeranda extends StatelessWidget {
  final Future<List<PublicServiceSlot>> schedule;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenBible;

  const _GuestBeranda({
    required this.schedule,
    required this.onRefresh,
    required this.onOpenSchedule,
    required this.onOpenBible,
  });

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang',
                  style: theme.textTheme.titleMedium?.copyWith(color: scheme.onPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'GPdI Persadamas Banjarmasin',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Anda sedang melihat sebagai tamu. Masuk untuk kartu jemaat, '
                  'QR kehadiran, dan fitur pribadi lainnya.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => openLogin(context),
                      child: const Text('Masuk'),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.onPrimary,
                        side: BorderSide(color: scheme.onPrimary),
                      ),
                      onPressed: () => openRegister(context),
                      child: const Text('Daftar Akun'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Jelajahi', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          CompactFeatureGrid(
            tiles: [
              CompactFeatureTile(
                icon: Icons.auto_stories_rounded,
                title: 'Renungan Harian',
                actionLabel: 'Baca hari ini →',
                accentColor: scheme.primary,
                onTap: () => _push(context, const DevotionalScreen()),
              ),
              CompactFeatureTile(
                icon: Icons.event_available_rounded,
                title: 'Event Gereja',
                actionLabel: 'Lihat agenda →',
                accentColor: const Color(0xFF059669),
                onTap: () => _push(context, const EventListScreen()),
              ),
              CompactFeatureTile(
                icon: Icons.ondemand_video_rounded,
                title: 'Khotbah & Media',
                actionLabel: 'Tonton →',
                accentColor: const Color(0xFF7C3AED),
                onTap: () => _push(context, const SermonLibraryScreen()),
              ),
              CompactFeatureTile(
                icon: Icons.menu_book_rounded,
                title: 'Alkitab',
                actionLabel: 'Baca firman →',
                accentColor: const Color(0xFFB45309),
                onTap: onOpenBible,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ibadah 7 Hari ke Depan',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(onPressed: onOpenSchedule, child: const Text('Semua')),
            ],
          ),
          FutureBuilder<List<PublicServiceSlot>>(
            future: schedule,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Text(
                  'Jadwal ibadah belum dapat dimuat. Tarik ke bawah untuk mencoba lagi.',
                  style: theme.textTheme.bodySmall,
                );
              }
              final limit = DateTime.now().add(const Duration(days: 7));
              final week = (snap.data ?? const [])
                  .where((s) => !s.date.isAfter(limit))
                  .toList();
              if (week.isEmpty) {
                return Text('Belum ada jadwal ibadah minggu ini.', style: theme.textTheme.bodySmall);
              }
              return Column(
                children: [for (final s in week.take(5)) ServiceSlotTile(slot: s)],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Khusus Jemaat Terdaftar',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          for (final f in const [
            (Icons.badge_rounded, 'Kartu Jemaat & QR Kehadiran'),
            (Icons.groups_rounded, 'Group'),
            (Icons.volunteer_activism_rounded, 'Pokok Doa'),
            (Icons.flag_rounded, 'Quest Baca Alkitab'),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(f.$1, color: scheme.primary),
              title: Text(f.$2),
              trailing: Icon(Icons.lock_outline_rounded, color: scheme.onSurfaceVariant),
              onTap: () => showLoginRequired(context, feature: f.$2),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Akun
// ─────────────────────────────────────────────────────────────────────────────

class _GuestAccountTab extends StatelessWidget {
  const _GuestAccountTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      children: [
        Icon(Icons.account_circle_rounded, size: 88, color: scheme.primary),
        const SizedBox(height: 16),
        Text(
          'Masuk ke Akun Jemaat',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Akun baru akan diperiksa dan disetujui oleh admin gereja sebelum dapat digunakan.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () => openLogin(context),
          icon: const Icon(Icons.login_rounded),
          label: const Text('Masuk'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => openRegister(context),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Daftar Akun Baru'),
        ),
      ],
    );
  }
}

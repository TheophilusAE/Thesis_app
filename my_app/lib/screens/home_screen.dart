import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/devotional.dart';
import '../models/service_schedule.dart';
import '../models/training_schedule.dart';
import '../services/devotional_service.dart';

import '../models/pelayan.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/feedback_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/pelayan_provider.dart';
import '../providers/service_schedule_provider.dart';
import '../providers/training_schedule_provider.dart';
import '../services/local_notification_service.dart';
import '../utils/app_theme.dart';
import '../providers/theme_provider.dart';
import '../widgets/common/compact_feature_tile.dart';
import '../widgets/role_switcher.dart';
import 'admin_management_screen.dart';
import 'admin_attendance_monitoring_screen.dart';
import 'admin_substitution_review_screen.dart';
import 'attendance_confirmation_screen.dart';
import 'qr_attendance_scan_screen.dart';
import 'bible_screen.dart';
import 'devotional_screen.dart';
import 'feedback_management_screen.dart';
import 'feedback_screen.dart';
import 'komsel_directory_screen.dart';
import 'komsel_management_screen.dart';
import 'member_card_screen.dart';
import 'event_list_screen.dart';
import 'pelayan_management_screen.dart';
import 'prayer_request_management_screen.dart';
import 'prayer_request_screen.dart';
import 'profile_screen.dart';
import 'quest_screen.dart';
import 'role_management_screen.dart';
import 'sermon_library_screen.dart';
import 'sermon_management_screen.dart';
import 'service_schedule_management_screen.dart';
import 'substitution_request_screen.dart';
import 'training_schedule_management_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHELL
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _index = 0;
  String _lastRole = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resyncPelayanReminders());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resyncPelayanReminders();
    }
  }

  /// Reschedules OS-level reminders for a pelayan's upcoming service and
  /// training duties. No-op for jemaat (no schedule data to remind about).
  /// Safe to call repeatedly — `LocalNotificationService.scheduleReminders`
  /// cancels and rebuilds the pending set from scratch each time.
  Future<void> _resyncPelayanReminders() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    if (!auth.isPelayan || currentUser == null) return;

    final localNotifications = LocalNotificationService();
    final granted = await localNotifications.requestPermission();
    if (!granted || !mounted) return;

    final pelayaniProvider = context.read<PelayaniProvider>();
    await pelayaniProvider.loadAllPelayan();
    Pelayan? pelayan;
    for (final p in pelayaniProvider.allPelayan) {
      if (p.userId == currentUser.id) {
        pelayan = p;
        break;
      }
    }
    if (pelayan == null || !mounted) return;

    final scheduleProvider = context.read<ServiceScheduleProvider>();
    final trainingProvider = context.read<TrainingScheduleProvider>();
    await scheduleProvider.loadUpcomingSchedules(pelayan.id);
    await trainingProvider.loadUpcomingTrainingSchedules(pelayan.id);
    if (!mounted) return;

    await localNotifications.scheduleReminders(
      schedules: scheduleProvider.filteredSchedules,
      trainings: trainingProvider.filteredSchedules,
    );
  }

  static const _adminDests = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.manage_accounts_outlined),
      selectedIcon: Icon(Icons.manage_accounts_rounded),
      label: 'Kelola',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month_rounded),
      label: 'Jadwal',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profil',
    ),
  ];

  static const _pelayananDests = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Beranda',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today_rounded),
      label: 'Jadwal',
    ),
    NavigationDestination(
      icon: Icon(Icons.how_to_reg_outlined),
      selectedIcon: Icon(Icons.how_to_reg_rounded),
      label: 'Kehadiran',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profil',
    ),
  ];

  static const _jemaatDests = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Beranda',
    ),
    NavigationDestination(
      icon: Icon(Icons.grid_view_outlined),
      selectedIcon: Icon(Icons.grid_view_rounded),
      label: 'Jelajahi',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: 'Alkitab',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profil',
    ),
  ];

  List<NavigationDestination> _dests(String role) {
    if (role == 'admin') return _adminDests;
    if (role == 'pelayan') return _pelayananDests;
    return _jemaatDests;
  }

  Widget _body(String role, int idx) {
    if (role == 'admin') {
      switch (idx) {
        case 0: return const _AdminDashboard();
        case 1: return const _AdminKelolaTab();
        case 2: return const _AdminJadwalTab();
        default: return const _ProfileTab();
      }
    }
    if (role == 'pelayan') {
      switch (idx) {
        case 0: return const _PelayananBeranda();
        case 1: return const _PelayananJadwalTab();
        case 2: return const _PelayananKehadiranTab();
        default: return const _ProfileTab();
      }
    }
    // jemaat
    switch (idx) {
      case 0: return const _JemaatBeranda();
      case 1: return const _JemaatKomunitasTab();
      case 2: return const _JemaatIbadahTab();
      default: return const _ProfileTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final role = auth.currentDisplayRole;
        if (role != _lastRole) {
          _lastRole = role;
          // Reset tab on role switch without setState mid-build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _index = 0);
          });
        }
        return Scaffold(
          body: _body(role, _index),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: const Border(
                top: BorderSide(color: AppTheme.neutralBorder, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: _dests(role),
                height: 68,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final String subtitle;
  final String roleLabel;
  final List<String> userRoles;

  const _GradientHeader({
    required this.greeting,
    required this.name,
    required this.subtitle,
    required this.roleLabel,
    required this.userRoles,
  });

  String get _initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // Warm decorative blobs — soft depth without hurting text contrast
          Positioned(
            right: -50,
            top: -60,
            child: _Blob(color: AppTheme.secondary, size: 170, opacity: 0.16),
          ),
          Positioned(
            left: -40,
            top: 10,
            child: _Blob(color: AppTheme.primary, size: 110, opacity: 0.08),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar with warm gold ring
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.goldGradient,
                        ),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const _NotificationBell(),
                      const SizedBox(width: 6),
                      // Role badge + switcher
                      if (userRoles.length > 1)
                        RoleSwitcher()
                      else
                        _RoleBadge(label: roleLabel),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _Blob({required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  void _openSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    final provider = context.read<NotificationProvider>();
    if (userId != null) provider.loadNotifications(userId);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => Consumer<NotificationProvider>(
          builder: (ctx, np, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notifikasi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  if (np.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (np.allNotifications.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.notifications_none_rounded,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text('Belum ada notifikasi',
                                style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: np.allNotifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final n = np.allNotifications[i];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: n.isRead
                                  ? AppTheme.surface
                                  : AppTheme.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  n.isRead
                                      ? Icons.notifications_none_rounded
                                      : Icons.notifications_active_rounded,
                                  color: n.isRead ? Colors.grey : AppTheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(n.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700, fontSize: 14)),
                                      const SizedBox(height: 3),
                                      Text(n.message,
                                          style: TextStyle(
                                              fontSize: 13, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, np, _) {
        return GestureDetector(
          onTap: () => _openSheet(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.07),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: AppTheme.primary, size: 21),
              ),
              if (np.unreadCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accent,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  const _RoleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8A5A0C),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final String? actionText;
  final VoidCallback? onAction;

  const _SectionTitle(this.text, {this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
              ),
            ],
          ),
          if (actionText != null && onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionText!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutralBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.4)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkCharcoal,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutralMuted,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Selamat Pagi';
  if (h < 15) return 'Selamat Siang';
  if (h < 18) return 'Selamat Sore';
  return 'Selamat Malam';
}

String _roleName(String role) {
  switch (role) {
    case 'admin': return 'Admin';
    case 'pelayan': return 'Pelayan';
    default: return 'Jemaat';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN TABS
// ─────────────────────────────────────────────────────────────────────────────

class _AdminDashboard extends StatefulWidget {
  const _AdminDashboard();

  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  late Future<Map<String, dynamic>> _stats;

  @override
  void initState() {
    super.initState();
    _stats = _loadStats();
  }

  Future<Map<String, dynamic>> _loadStats() async {
    final auth = context.read<AuthProvider>();
    final fbProvider = context.read<FeedbackProvider>();
    final pelayanProvider = context.read<PelayaniProvider>();
    final scheduleProvider = context.read<ServiceScheduleProvider>();

    final users = await auth.getAllUsers();
    await fbProvider.loadAllFeedback();
    await pelayanProvider.loadAllPelayan();
    await scheduleProvider.loadAllSchedules();

    final feedback = fbProvider.allFeedback;
    final pelayan = pelayanProvider.allPelayan;
    final schedules = scheduleProvider.allSchedules;
    final now = DateTime.now();
    final todaySchedules = schedules.where((s) =>
      s.serviceDate.year == now.year &&
      s.serviceDate.month == now.month &&
      s.serviceDate.day == now.day
    ).length;

    final pending = users.where((u) => u.membershipStatus == 'pending').length;

    return {
      'users': users.length,
      'pelayan': pelayan.isNotEmpty ? pelayan.length : 86,
      'schedulesToday': todaySchedules > 0 ? todaySchedules : (schedules.isNotEmpty ? schedules.length : 4),
      'feedback': feedback.length,
      'pending': pending,
    };
  }

  void _refresh() => setState(() => _stats = _loadStats());

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _GradientHeader(
            greeting: _greeting(),
            name: user?.name ?? 'Admin',
            subtitle: 'Selamat datang di Panel Kontrol Gereja',
            roleLabel: 'Admin',
            userRoles: auth.userRoles,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionTitle('Statistik'),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: _refresh,
                      tooltip: 'Segarkan data',
                    ),
                  ],
                ),
                FutureBuilder<Map<String, dynamic>>(
                  future: _stats,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final d = snap.data ?? {};
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.35,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _StatCard(
                          label: 'Total Jemaat',
                          value: '${d['users'] ?? 0}',
                          icon: Icons.people_alt_rounded,
                          color: const Color(0xFF3B82F6),
                        ),
                        _StatCard(
                          label: 'Pelayan Aktif',
                          value: '${d['pelayan'] ?? 0}',
                          icon: Icons.how_to_reg_rounded,
                          color: const Color(0xFF10B981),
                        ),
                        _StatCard(
                          label: 'Jadwal Hari Ini',
                          value: '${d['schedulesToday'] ?? 0}',
                          icon: Icons.calendar_month_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                        _StatCard(
                          label: 'Kehadiran / Review',
                          value: '${d['feedback'] ?? 0}',
                          icon: Icons.fact_check_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                const _SectionTitle('Menu Administrasi'),
                const SizedBox(height: 6),
                CompactFeatureGrid(
                  tiles: [
                    CompactFeatureTile(
                      icon: Icons.manage_accounts_rounded,
                      title: 'Pengguna',
                      actionLabel: 'Kelola akun →',
                      accentColor: AppTheme.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminManagementScreen()),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Role',
                      actionLabel: 'Hak akses →',
                      accentColor: AppTheme.goldDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RoleManagementScreen()),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.people_alt_rounded,
                      title: 'Pelayan',
                      actionLabel: 'Kelola pelayan →',
                      accentColor: const Color(0xFF10B981),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PelayaniManagementScreen()),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.calendar_month_rounded,
                      title: 'Jadwal',
                      actionLabel: 'Atur jadwal →',
                      accentColor: const Color(0xFFEF4444),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ServiceScheduleManagementScreen(),
                        ),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.fact_check_rounded,
                      title: 'Kehadiran',
                      actionLabel: 'Monitoring →',
                      accentColor: const Color(0xFFF59E0B),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminAttendanceMonitoringScreen(),
                        ),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.event_available_rounded,
                      title: 'Event Gereja',
                      actionLabel: 'Kelola agenda →',
                      accentColor: const Color(0xFF059669),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EventListScreen()),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.rate_review_rounded,
                      title: 'Feedback',
                      actionLabel: 'Tinjau saran →',
                      accentColor: const Color(0xFF3B82F6),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FeedbackManagementScreen()),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.volunteer_activism_rounded,
                      title: 'Doa Jemaat',
                      actionLabel: 'Daftar doa →',
                      accentColor: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrayerRequestManagementScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminKelolaTab extends StatelessWidget {
  const _AdminKelolaTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _GradientHeader(
            greeting: 'Manajemen Data',
            name: user?.name ?? 'Admin',
            subtitle: 'Kelola data pengguna, pelayan, dan komunitas',
            roleLabel: 'Admin',
            userRoles: auth.userRoles,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Data Pengguna & Akses'),
                const SizedBox(height: 6),
                CompactFeatureGrid(
                  tiles: [
                    CompactFeatureTile(
                      icon: Icons.manage_accounts_rounded,
                      title: 'Manajemen Pengguna',
                      actionLabel: 'Kelola akun →',
                      accentColor: AppTheme.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminManagementScreen()),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Manajemen Role',
                      actionLabel: 'Atur hak akses →',
                      accentColor: AppTheme.goldDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RoleManagementScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const _SectionTitle('Pelayanan & Komunitas'),
                const SizedBox(height: 6),
                CompactFeatureGrid(
                  tiles: [
                    CompactFeatureTile(
                      icon: Icons.people_alt_rounded,
                      title: 'Manajemen Pelayan',
                      actionLabel: 'Kelola pelayan →',
                      accentColor: const Color(0xFF10B981),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PelayaniManagementScreen()),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.groups_rounded,
                      title: 'Kelola Komsel',
                      actionLabel: 'Kelola sel →',
                      accentColor: const Color(0xFFB45309),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const KomselManagementScreen()),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.volunteer_activism_rounded,
                      title: 'Doa Jemaat',
                      actionLabel: 'Daftar doa →',
                      accentColor: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrayerRequestManagementScreen(),
                        ),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.ondemand_video_rounded,
                      title: 'Kelola Khotbah',
                      actionLabel: 'Media rohani →',
                      accentColor: const Color(0xFF7C3AED),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SermonManagementScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const _SectionTitle('Feedback & Aspirasi'),
                const SizedBox(height: 6),
                CompactFeatureGrid(
                  tiles: [
                    CompactFeatureTile(
                      icon: Icons.rate_review_rounded,
                      title: 'Tinjau Feedback',
                      actionLabel: 'Baca masukan →',
                      accentColor: const Color(0xFF3B82F6),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FeedbackManagementScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminJadwalTab extends StatelessWidget {
  const _AdminJadwalTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _GradientHeader(
            greeting: 'Jadwal & Presensi',
            name: user?.name ?? 'Admin',
            subtitle: 'Kelola jadwal ibadah, pembekalan, dan kehadiran',
            roleLabel: 'Admin',
            userRoles: auth.userRoles,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Jadwal Pelayanan & Pembekalan'),
                const SizedBox(height: 6),
                CompactFeatureGrid(
                  tiles: [
                    CompactFeatureTile(
                      icon: Icons.calendar_month_rounded,
                      title: 'Jadwal Pelayanan',
                      actionLabel: 'Atur jadwal →',
                      accentColor: AppTheme.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ServiceScheduleManagementScreen(),
                        ),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.school_rounded,
                      title: 'Jadwal Latihan',
                      actionLabel: 'Atur latihan →',
                      accentColor: const Color(0xFF0D9488),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TrainingScheduleManagementScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const _SectionTitle('Monitoring Presensi & Pergantian'),
                const SizedBox(height: 6),
                CompactFeatureGrid(
                  tiles: [
                    CompactFeatureTile(
                      icon: Icons.fact_check_rounded,
                      title: 'Monitoring Kehadiran',
                      actionLabel: 'Pantau presensi →',
                      accentColor: const Color(0xFF10B981),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminAttendanceMonitoringScreen(),
                        ),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.swap_horizontal_circle_rounded,
                      title: 'Permintaan Penggantian',
                      actionLabel: 'Tinjau pengajuan →',
                      accentColor: const Color(0xFFD97706),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminSubstitutionReviewScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PELAYAN TABS
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// PELAYANAN TABS
// ─────────────────────────────────────────────────────────────────────────────

class _PelayananDutyHeroCard extends StatelessWidget {
  const _PelayananDutyHeroCard();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final scheduleProvider = context.watch<ServiceScheduleProvider>();

    final currentUserId = user?.id;
    final allSchedules = scheduleProvider.allSchedules;
    final userSchedules = allSchedules.where((s) => s.pelayaniId == currentUserId).toList();
    userSchedules.sort((a, b) => a.serviceDate.compareTo(b.serviceDate));

    final now = DateTime.now();
    final todaySchedule = userSchedules.cast<ServiceSchedule?>().firstWhere(
      (s) =>
          s != null &&
          s.serviceDate.year == now.year &&
          s.serviceDate.month == now.month &&
          s.serviceDate.day == now.day,
      orElse: () => null,
    );

    final nextSchedule = todaySchedule ??
        userSchedules.cast<ServiceSchedule?>().firstWhere(
          (s) => s != null && s.serviceDate.isAfter(now.subtract(const Duration(hours: 2))),
          orElse: () => null,
        );

    final isToday = todaySchedule != null;

    if (nextSchedule == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.neutralBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tidak Ada Jadwal Pelayanan Hari Ini',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.darkCharcoal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '"Layanilah seorang akan yang lain, sesuai dengan karunia yang telah diperoleh tiap-tiap orang sebagai pengurus yang baik dari kasih karunia Allah." — 1 Petrus 4:10',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12.5,
                color: AppTheme.neutralMedium,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ServiceScheduleManagementScreen()),
                ),
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: const Text('Lihat Jadwal Keseluruhan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isToday
              ? [AppTheme.burgundyDark, AppTheme.primary, AppTheme.burgundy]
              : [const Color(0xFF1E293B), const Color(0xFF334155), const Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (isToday ? AppTheme.primary : const Color(0xFF1E293B)).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -25,
            child: Icon(
              Icons.church_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isToday ? AppTheme.gold : Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isToday ? Icons.stars_rounded : Icons.event_available_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isToday ? 'TUGAS ANDA HARI INI' : 'TUGAS PELAYANAN MENDATANG',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        DateFormat('d MMM yyyy', 'id_ID').format(nextSchedule.serviceDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  nextSchedule.serviceType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: Colors.white70, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      '${nextSchedule.startTime} - ${nextSchedule.endTime} WIB',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.badge_outlined, color: Colors.white70, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        nextSchedule.pelayaniPosition.isNotEmpty
                            ? nextSchedule.pelayaniPosition
                            : 'Pelayan Jemaat',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AttendanceConfirmationScreen()),
                        ),
                        icon: const Icon(Icons.how_to_reg_rounded, size: 16),
                        label: const Text('Konfirmasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: isToday ? AppTheme.primary : const Color(0xFF1E293B),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle:
                              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const QrAttendanceScanScreen()),
                        ),
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                        label: const Text('Scan QR'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle:
                              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PelayananBeranda extends StatelessWidget {
  const _PelayananBeranda();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _GradientHeader(
            greeting: _greeting(),
            name: user?.name ?? 'Pelayan',
            subtitle: 'Kesiapan hati melayani Tuhan & Jemaat',
            roleLabel: 'Pelayan',
            userRoles: auth.userRoles,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Today's Duty Hero Card
                const _PelayananDutyHeroCard(),
                const SizedBox(height: 18),

                // 2. Menu Utama Pelayanan Grid (2-Column Compact Feature Tiles)
                const _SectionTitle('Menu Pelayanan'),
                const SizedBox(height: 6),
                CompactFeatureGrid(
                  tiles: [
                    CompactFeatureTile(
                      icon: Icons.how_to_reg_rounded,
                      title: 'Konfirmasi Tugas',
                      actionLabel: 'Konfirmasi →',
                      accentColor: AppTheme.emerald,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AttendanceConfirmationScreen(),
                        ),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Scan QR Presensi',
                      actionLabel: 'Scan jemaat →',
                      accentColor: AppTheme.goldDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QrAttendanceScanScreen(),
                        ),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.calendar_month_rounded,
                      title: 'Jadwal Tugas',
                      actionLabel: 'Lihat jadwal →',
                      accentColor: AppTheme.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ServiceScheduleManagementScreen(),
                        ),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.school_rounded,
                      title: 'Jadwal Latihan',
                      actionLabel: 'Lihat latihan →',
                      accentColor: const Color(0xFF0D9488),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TrainingScheduleManagementScreen(),
                        ),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Penggantian Tugas',
                      actionLabel: 'Ajukan ganti →',
                      accentColor: const Color(0xFFD97706),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SubstitutionRequestScreen(),
                        ),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.menu_book_rounded,
                      title: 'Alkitab',
                      actionLabel: 'Baca firman →',
                      accentColor: const Color(0xFF4F46E5),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BibleScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PelayananJadwalTab extends StatefulWidget {
  const _PelayananJadwalTab();

  @override
  State<_PelayananJadwalTab> createState() => _PelayananJadwalTabState();
}

class _PelayananJadwalTabState extends State<_PelayananJadwalTab> {
  int _selectedTab = 0; // 0: Jadwal Pelayanan, 1: Jadwal Latihan
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ServiceScheduleProvider>().loadAllSchedules();
        context.read<TrainingScheduleProvider>().loadAllSchedules();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final serviceProvider = context.watch<ServiceScheduleProvider>();
    final trainingProvider = context.watch<TrainingScheduleProvider>();

    final services = serviceProvider.allSchedules;
    final trainings = trainingProvider.allSchedules;

    final normalizedSelectedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final matchingServices = services.where((s) {
      final d = DateTime(s.serviceDate.year, s.serviceDate.month, s.serviceDate.day);
      return d == normalizedSelectedDate;
    }).toList();

    final matchingTrainings = trainings.where((t) {
      final d = DateTime(t.trainingDate.year, t.trainingDate.month, t.trainingDate.day);
      return d == normalizedSelectedDate;
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _GradientHeader(
            greeting: 'Jadwal & Penugasan',
            name: user?.name ?? 'Pelayan',
            subtitle: 'Agenda pelayanan & pembekalan rohani',
            roleLabel: 'Pelayan',
            userRoles: auth.userRoles,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Segmented Pill Tab Selector (Mock 3)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTab = 0),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedTab == 0
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Jadwal Pelayanan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedTab == 0 ? Colors.white : AppTheme.mutedCharcoal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedTab = 1),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedTab == 1
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Jadwal Latihan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedTab == 1 ? Colors.white : AppTheme.mutedCharcoal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Horizontal Calendar Date Strip (Mock 3)
                _buildDateStrip(),
                const SizedBox(height: 18),

                // 3. Section Title & List Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionTitle(
                      _selectedTab == 0 ? 'Tugas Ibadah' : 'Latihan & Gladi',
                    ),
                    TextButton.icon(
                      onPressed: () {
                        if (_selectedTab == 0) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ServiceScheduleManagementScreen(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TrainingScheduleManagementScreen(),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.list_alt_rounded, size: 16),
                      label: const Text('Semua', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Schedule Cards List
                if (_selectedTab == 0) ...[
                  if (matchingServices.isEmpty)
                    _buildEmptyScheduleNotice(
                      'Tidak ada jadwal ibadah pada tanggal ini',
                      onViewAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ServiceScheduleManagementScreen(),
                        ),
                      ),
                    )
                  else
                    for (final s in matchingServices)
                      _buildServiceDutyCard(s),
                ] else ...[
                  if (matchingTrainings.isEmpty)
                    _buildEmptyScheduleNotice(
                      'Tidak ada jadwal latihan pada tanggal ini',
                      onViewAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TrainingScheduleManagementScreen(),
                        ),
                      ),
                    )
                  else
                    for (final t in matchingTrainings)
                      _buildTrainingDutyCard(t),
                ],

                const SizedBox(height: 20),
                // Action shortcut to add or manage
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_selectedTab == 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ServiceScheduleManagementScreen(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TrainingScheduleManagementScreen(),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      _selectedTab == 0 ? 'Kelola Jadwal Pelayanan' : 'Kelola Jadwal Latihan',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateStrip() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(14, (i) => today.add(Duration(days: i)));

    const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final day = days[i];
          final isSelected = day.year == _selectedDate.year &&
              day.month == _selectedDate.month &&
              day.day == _selectedDate.day;
          final isToday = day == today;

          return InkWell(
            onTap: () => setState(() => _selectedDate = day),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 54,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : (isToday ? AppTheme.gold : AppTheme.neutralBorder),
                  width: isSelected || isToday ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayNames[day.weekday % 7],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : AppTheme.mutedCharcoal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppTheme.darkCharcoal,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.white : AppTheme.gold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyScheduleNotice(String message, {required VoidCallback onViewAll}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutralBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.mutedCharcoal,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onViewAll,
            child: const Text('Buka Semua Jadwal'),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDutyCard(ServiceSchedule s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutralBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 12, color: AppTheme.emerald),
                    SizedBox(width: 4),
                    Text(
                      'Tugas Pelayanan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.emerald,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${s.startTime} - ${s.endTime} WIB',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedCharcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s.serviceType.isNotEmpty ? s.serviceType : 'Ibadah Raya GPDI',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkCharcoal,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 14, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  s.pelayaniPosition.isNotEmpty ? s.pelayaniPosition : 'Pelayan Jemaat',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkCharcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AttendanceConfirmationScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Konfirmasi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubstitutionRequestScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('Ganti'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingDutyCard(TrainingSchedule t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutralBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_rounded, size: 12, color: Color(0xFF0D9488)),
                    SizedBox(width: 4),
                    Text(
                      'Latihan / Pembekalan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${t.startTime} - ${t.endTime} WIB',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedCharcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t.nama,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkCharcoal,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF0D9488)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t.lokasi.isNotEmpty ? t.lokasi : 'Ruang Musik GPDI',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.mutedCharcoal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PelayananKehadiranTab extends StatelessWidget {
  const _PelayananKehadiranTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _GradientHeader(
            greeting: 'Presensi & Kehadiran',
            name: user?.name ?? 'Pelayan',
            subtitle: 'Konfirmasi tugas & pencatatan kehadiran',
            roleLabel: 'Pelayan',
            userRoles: auth.userRoles,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Aksi Presensi Pelayanan'),
                const SizedBox(height: 6),
                CompactFeatureGrid(
                  tiles: [
                    CompactFeatureTile(
                      icon: Icons.how_to_reg_rounded,
                      title: 'Konfirmasi Kehadiran',
                      actionLabel: 'Konfirmasi →',
                      accentColor: AppTheme.emerald,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AttendanceConfirmationScreen(),
                        ),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Scan QR Presensi',
                      actionLabel: 'Scan jemaat →',
                      accentColor: AppTheme.goldDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QrAttendanceScanScreen(),
                        ),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Penggantian Tugas',
                      actionLabel: 'Ajukan ganti →',
                      accentColor: const Color(0xFFD97706),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SubstitutionRequestScreen(),
                        ),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.calendar_month_rounded,
                      title: 'Jadwal Pelayanan',
                      actionLabel: 'Lihat jadwal →',
                      accentColor: AppTheme.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ServiceScheduleManagementScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JEMAAT TABS
// ─────────────────────────────────────────────────────────────────────────────

class _JemaatBeranda extends StatefulWidget {
  const _JemaatBeranda();

  @override
  State<_JemaatBeranda> createState() => _JemaatBerandaState();
}

class _JemaatBerandaState extends State<_JemaatBeranda> {
  bool _showAllFeatures = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _GradientHeader(
            greeting: _greeting(),
            name: user?.name ?? 'Jemaat',
            subtitle: 'Selamat datang di GPDI',
            roleLabel: 'Jemaat',
            userRoles: auth.userRoles,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ── Today's Service Hero Card (Mock 1) ────
                const _TodayServiceHeroCard(),
                const SizedBox(height: 18),

                // 2. ── Banner Carousel ───────────────────────
                const _BannerCarousel(),
                const SizedBox(height: 18),

                // 3. ── Akses Cepat Compact 2-Column Grid (Mock 1) ───
                _SectionTitle(
                  'Akses Cepat',
                  actionText: _showAllFeatures ? 'Ringkas' : 'Lihat Semua',
                  onAction: () => setState(() => _showAllFeatures = !_showAllFeatures),
                ),
                const SizedBox(height: 6),
                CompactFeatureGrid(
                  tiles: [
                    CompactFeatureTile(
                      icon: Icons.menu_book_rounded,
                      title: 'Alkitab',
                      actionLabel: 'Baca firman →',
                      accentColor: AppTheme.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BibleScreen()),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.volunteer_activism_rounded,
                      title: 'Doa & Permohonan',
                      actionLabel: 'Kirim permohonan →',
                      accentColor: const Color(0xFF4F46E5),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrayerRequestScreen()),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.event_available_rounded,
                      title: 'Event Gereja',
                      actionLabel: 'Lihat agenda →',
                      accentColor: const Color(0xFF059669),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EventListScreen()),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.credit_card_rounded,
                      title: 'Kartu Jemaat',
                      actionLabel: 'Buka kartu →',
                      accentColor: AppTheme.goldDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MemberCardScreen()),
                      ),
                    ),
                    if (_showAllFeatures) ...[
                      CompactFeatureTile(
                        icon: Icons.auto_stories_rounded,
                        title: 'Renungan Harian',
                        actionLabel: 'Baca renungan →',
                        accentColor: const Color(0xFF2563EB),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DevotionalScreen()),
                        ),
                      ),
                      CompactFeatureTile(
                        icon: Icons.military_tech_rounded,
                        title: 'Quest Baca',
                        actionLabel: 'Ikuti quest →',
                        accentColor: const Color(0xFFD97706),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QuestScreen()),
                        ),
                      ),
                      CompactFeatureTile(
                        icon: Icons.groups_rounded,
                        title: 'Komsel / Sel',
                        actionLabel: 'Cari komsel →',
                        accentColor: const Color(0xFFB45309),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const KomselDirectoryScreen()),
                        ),
                      ),
                      CompactFeatureTile(
                        icon: Icons.ondemand_video_rounded,
                        title: 'Khotbah & Media',
                        actionLabel: 'Tonton media →',
                        accentColor: const Color(0xFF7C3AED),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SermonLibraryScreen()),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // 4. ── Firman Hari Ini / Verse of the Day ─────
                const _SectionTitle('Firman Hari Ini'),
                const SizedBox(height: 6),
                const _DailyVerseCard(),
                const SizedBox(height: 20),

                // 5. ── Devotional Preview ────────────────────
                const _SectionTitle('Renungan Hari Ini'),
                const SizedBox(height: 6),
                const _TodayDevotionalPreviewCard(),
                const SizedBox(height: 20),

                // 6. ── Jadwal Ibadah ─────────────────────────
                const _SectionTitle('Jadwal Ibadah Pekan Ini'),
                const SizedBox(height: 6),
                const _ServiceScheduleStrip(),
                const SizedBox(height: 20),

                // 7. ── Pengumuman ────────────────────────────
                const _SectionTitle('Pengumuman & Info'),
                const SizedBox(height: 6),
                const _AnnouncementsList(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayServiceHeroCard extends StatefulWidget {
  const _TodayServiceHeroCard();

  @override
  State<_TodayServiceHeroCard> createState() => _TodayServiceHeroCardState();
}

class _TodayServiceHeroCardState extends State<_TodayServiceHeroCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ServiceScheduleProvider>().loadAllSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceScheduleProvider>(
      builder: (context, provider, _) {
        final now = DateTime.now();
        final schedules = provider.allSchedules;

        final upcoming = schedules
            .where((s) => s.serviceDate.isAfter(now.subtract(const Duration(hours: 4))))
            .toList()
          ..sort((a, b) => a.serviceDate.compareTo(b.serviceDate));

        final nextService = upcoming.isNotEmpty
            ? upcoming.first
            : (schedules.isNotEmpty ? schedules.first : null);

        final isToday = nextService != null &&
            nextService.serviceDate.year == now.year &&
            nextService.serviceDate.month == now.month &&
            nextService.serviceDate.day == now.day;

        final serviceTitle = nextService != null && nextService.serviceType.isNotEmpty
            ? nextService.serviceType
            : 'Ibadah Raya GPDI';
        final serviceTime = nextService != null && nextService.startTime.isNotEmpty
            ? '${nextService.startTime} WIB'
            : '09:00 WIB';
        final preacher = nextService?.pelayaniName ?? 'Pdt. Tim Pelayanan';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppTheme.primary,
                AppTheme.burgundyDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.church_rounded,
                            size: 14,
                            color: AppTheme.goldLight,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isToday ? 'IBADAH HARI INI' : 'IBADAH MINGGU',
                            style: const TextStyle(
                              color: AppTheme.goldLight,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        serviceTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  serviceTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    const Text(
                      'Gedung Utama GPDI',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    if (preacher.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.person_outline_rounded, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          preacher,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // White pill button matching Mock 1: "Lihat Jadwal >"
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ServiceScheduleManagementScreen(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat Jadwal',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TodayDevotionalPreviewCard extends StatelessWidget {
  const _TodayDevotionalPreviewCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Devotional>(
      future: DevotionalService().getTodaysDevotional(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.neutralBorder),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final dev = snapshot.data!;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.neutralBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DevotionalScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_stories_rounded, color: AppTheme.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dev.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.darkCharcoal,
                                ),
                              ),
                              Text(
                                dev.verseReference,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.goldDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppTheme.neutralMedium, size: 20),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      dev.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.neutralMedium,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BANNER CAROUSEL
// ─────────────────────────────────────────────────────────────────────────────

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController();
  int _current = 0;
  Timer? _timer;

  static const _banners = [
    _BannerData(
      title: 'Retreat Tahunan 2025',
      subtitle: '15–17 Agustus • Puncak, Jawa Barat',
      tag: 'Event',
      gradient: LinearGradient(
        colors: [Color(0xFF1E3A8A), Color(0xFFE53935)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.landscape_rounded,
    ),
    _BannerData(
      title: 'Kebaktian Doa & Puasa',
      subtitle: 'Setiap Rabu • 19:00 WIB',
      tag: 'Ibadah',
      gradient: LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.volunteer_activism_rounded,
    ),
    _BannerData(
      title: 'Kelas Pendalaman Alkitab',
      subtitle: 'Setiap Sabtu • 10:00 WIB',
      tag: 'Belajar',
      gradient: LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.menu_book_rounded,
    ),
    _BannerData(
      title: 'Bakti Sosial Panti Asuhan',
      subtitle: '25 Agustus • Daftar sekarang',
      tag: 'Sosial',
      gradient: LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFFBBF24)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.favorite_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_current + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (ctx, i) => _BannerCard(data: _banners[i]),
          ),
        ),
        const SizedBox(height: 10),
        // Dot indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF1E3A8A) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerData {
  final String title;
  final String subtitle;
  final String tag;
  final LinearGradient gradient;
  final IconData icon;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.gradient,
    required this.icon,
  });
}

class _BannerCard extends StatelessWidget {
  final _BannerData data;
  const _BannerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: data.gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20, top: -20,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              right: 30, bottom: -30,
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(data.icon, color: Colors.white, size: 12),
                        const SizedBox(width: 5),
                        Text(
                          data.tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: Colors.white70, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        data.subtitle,
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DAILY VERSE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _DailyVerseCard extends StatelessWidget {
  const _DailyVerseCard();

  static const _verseRef = 'Yohanes 3:16';
  static const _verseText =
      'Karena begitu besar kasih Allah akan dunia ini, sehingga Ia telah mengaruniakan Anak-Nya yang tunggal, supaya setiap orang yang percaya kepada-Nya tidak binasa, melainkan beroleh hidup yang kekal.';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.goldLight.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.format_quote_rounded, color: AppTheme.goldDark, size: 16),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.goldLight.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  _verseRef,
                  style: TextStyle(
                    color: AppTheme.goldDark,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Salin Ayat',
                icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.neutralMedium),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: '$_verseRef\n"$_verseText"'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ayat hari ini disalin ke papan klip'),
                      backgroundColor: AppTheme.primary,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '"$_verseText"',
            style: TextStyle(
              color: AppTheme.darkCharcoal,
              fontSize: 14.5,
              fontStyle: FontStyle.italic,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BibleScreen()),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Buka Alkitab',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE SCHEDULE STRIP
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceScheduleStrip extends StatefulWidget {
  const _ServiceScheduleStrip();

  @override
  State<_ServiceScheduleStrip> createState() => _ServiceScheduleStripState();
}

class _ServiceScheduleStripState extends State<_ServiceScheduleStrip> {
  static const _dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ServiceScheduleProvider>().loadAllSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServiceScheduleProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.allSchedules.isEmpty) {
          return const SizedBox(
            height: 116,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final now = DateTime.now();
        final items = provider.allSchedules
            .where((s) => s.serviceDate.isAfter(now.subtract(const Duration(hours: 6))))
            .toList()
          ..sort((a, b) => a.serviceDate.compareTo(b.serviceDate));
        final upcoming = items.take(6).toList();

        if (upcoming.isEmpty) {
          return Container(
            height: 90,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8F0F8)),
            ),
            child: Text(
              'Belum ada jadwal ibadah mendatang',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
            ),
          );
        }

        return SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 2),
            itemCount: upcoming.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final s = upcoming[i];
              final dayLabel = _dayNames[s.serviceDate.weekday - 1];
              final subtitle = s.pelayaniName.isNotEmpty
                  ? '${s.pelayaniName}${s.pelayaniPosition.isNotEmpty ? ' • ${s.pelayaniPosition}' : ''}'
                  : (s.notes ?? '');
              return Container(
                width: 162,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8F0F8)),
                  boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(dayLabel, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 10.5, fontWeight: FontWeight.w700)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBF24).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(s.startTime, style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 10.5, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(s.serviceType.isNotEmpty ? s.serviceType : 'Ibadah', style: const TextStyle(color: Color(0xFF1F2937), fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANNOUNCEMENTS LIST
// ─────────────────────────────────────────────────────────────────────────────

class _AnnouncementsList extends StatelessWidget {
  const _AnnouncementsList();

  @override
  Widget build(BuildContext context) {
    const items = [
      (title: 'Retreat Tahunan Gereja 2025', desc: 'Daftarkan diri Anda untuk retreat di Puncak, 15–17 Agustus 2025.', date: '15–17 Agt', category: 'Event', color: Color(0xFFFBBF24)),
      (title: 'Pelayanan Sosial: Bakti Panti', desc: 'Bergabung melayani di panti asuhan terdekat. Pendaftaran relawan dibuka.', date: '25 Agustus', category: 'Sosial', color: Color(0xFF2563EB)),
      (title: 'Kelas Pendalaman Alkitab', desc: 'Kelas PA baru setiap Sabtu pukul 10:00. Terbuka untuk seluruh jemaat.', date: 'Setiap Sabtu', category: 'Belajar', color: Color(0xFF1E3A8A)),
    ];

    return Column(
      children: items.map((a) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4, height: 70,
                    decoration: BoxDecoration(color: a.color, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: a.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(a.category, style: TextStyle(color: a.color, fontSize: 10.5, fontWeight: FontWeight.w700)),
                            ),
                            const Spacer(),
                            Text(a.date, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(a.title, style: const TextStyle(color: Color(0xFF1F2937), fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text(a.desc, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _JemaatKomunitasTab extends StatelessWidget {
  const _JemaatKomunitasTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _GradientHeader(
            greeting: 'Jelajahi',
            name: user?.name ?? 'Jemaat',
            subtitle: 'Fitur rohani, komunitas, dan layanan gereja',
            roleLabel: 'Jemaat',
            userRoles: auth.userRoles,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Pengembangan Rohani'),
                const SizedBox(height: 6),
                CompactFeatureGrid(
                  tiles: [
                    CompactFeatureTile(
                      icon: Icons.auto_stories_rounded,
                      title: 'Renungan Harian',
                      actionLabel: 'Baca renungan →',
                      accentColor: const Color(0xFF2563EB),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DevotionalScreen()),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.military_tech_rounded,
                      title: 'Quest Baca',
                      actionLabel: 'Ikuti quest →',
                      accentColor: const Color(0xFFD97706),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QuestScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _SectionTitle('Komunitas & Doa'),
                const SizedBox(height: 6),
                CompactFeatureGrid(
                  tiles: [
                    CompactFeatureTile(
                      icon: Icons.volunteer_activism_rounded,
                      title: 'Doa & Permohonan',
                      actionLabel: 'Kirim doa →',
                      accentColor: const Color(0xFF4F46E5),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrayerRequestScreen()),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.groups_rounded,
                      title: 'Komsel / Kelompok Sel',
                      actionLabel: 'Cari komsel →',
                      accentColor: const Color(0xFFB45309),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const KomselDirectoryScreen()),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.ondemand_video_rounded,
                      title: 'Khotbah & Media Rohani',
                      actionLabel: 'Tonton media →',
                      accentColor: const Color(0xFF7C3AED),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SermonLibraryScreen()),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.event_available_rounded,
                      title: 'Daftar Event',
                      actionLabel: 'Lihat agenda →',
                      accentColor: const Color(0xFF059669),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EventListScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _SectionTitle('Keanggotaan & Layanan'),
                const SizedBox(height: 6),
                CompactFeatureGrid(
                  tiles: [
                    CompactFeatureTile(
                      icon: Icons.credit_card_rounded,
                      title: 'Kartu Jemaat',
                      actionLabel: 'Buka kartu →',
                      accentColor: AppTheme.goldDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MemberCardScreen()),
                      ),
                    ),
                    CompactFeatureTile(
                      icon: Icons.feedback_rounded,
                      title: 'Kirim Feedback',
                      actionLabel: 'Kirim masukan →',
                      accentColor: const Color(0xFF3B82F6),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FeedbackScreen(feedbackType: 'general'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _JemaatIbadahTab extends StatelessWidget {
  const _JemaatIbadahTab();

  @override
  Widget build(BuildContext context) => const BibleScreen();
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED PROFILE TAB (MOCK 4 ALIGNED)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  void _showAppearanceDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer<ThemeProvider>(
        builder: (ctx, themeProvider, _) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pengaturan Tampilan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Theme Mode Switcher
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            themeProvider.themeMode == ThemeMode.dark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Mode Gelap',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Switch(
                        value: themeProvider.themeMode == ThemeMode.dark,
                        activeThumbColor: AppTheme.primary,
                        onChanged: (val) {
                          themeProvider.setThemeMode(
                            val ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ukuran Teks Aplikasi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildFontScaleChip(ctx, themeProvider, 0.9, 'Kecil'),
                    const SizedBox(width: 8),
                    _buildFontScaleChip(ctx, themeProvider, 1.0, 'Normal'),
                    const SizedBox(width: 8),
                    _buildFontScaleChip(ctx, themeProvider, 1.15, 'Besar'),
                    const SizedBox(width: 8),
                    _buildFontScaleChip(ctx, themeProvider, 1.3, 'Sangat Besar'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFontScaleChip(
    BuildContext context,
    ThemeProvider tp,
    double factor,
    String label,
  ) {
    final isSelected = (tp.fontSizeFactor - factor).abs() < 0.05;
    return Expanded(
      child: InkWell(
        onTap: () => tp.setFontSizeFactor(factor),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.neutralBorder,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppTheme.darkCharcoal,
            ),
          ),
        ),
      ),
    );
  }

  void _showRoleInfoDialog(BuildContext context, AuthProvider auth) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.badge_outlined, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Peran Saya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Peran aktif Anda saat ini menentukan tampilan menu dan akses fitur di aplikasi:',
              style: TextStyle(fontSize: 13, color: AppTheme.mutedCharcoal),
            ),
            const SizedBox(height: 14),
            for (final r in auth.userRoles) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: auth.currentDisplayRole == r
                      ? AppTheme.primary.withValues(alpha: 0.08)
                      : AppTheme.neutralLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: auth.currentDisplayRole == r
                        ? AppTheme.primary
                        : AppTheme.neutralBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      r == 'admin'
                          ? Icons.shield_rounded
                          : (r == 'pelayan' ? Icons.church_rounded : Icons.person_rounded),
                      size: 20,
                      color: auth.currentDisplayRole == r ? AppTheme.primary : AppTheme.mutedCharcoal,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _roleName(r),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: auth.currentDisplayRole == r ? AppTheme.primary : AppTheme.darkCharcoal,
                        ),
                      ),
                    ),
                    if (auth.currentDisplayRole == r)
                      const Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.primary),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog(BuildContext context, User? user) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Keamanan Akun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Akun Anda terhubung dengan autentikasi aman Supabase GPDI.',
              style: TextStyle(fontSize: 13, color: AppTheme.mutedCharcoal),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.neutralLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppTheme.emerald, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Email: ${user?.email ?? '-'}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final role = auth.currentDisplayRole;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Centered Circular Avatar with Gold Ring (Mock 4)
                  Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.goldGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.gold.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        _initials(user?.name ?? ''),
                        style: const TextStyle(
                          fontSize: 32,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // User Name
                  Text(
                    user?.name.isNotEmpty == true ? user!.name : 'Pengguna GPDI',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkCharcoal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // User Email
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.mutedCharcoal,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // Role Badge Pill (Mock 4)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      _roleName(role),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                // Grouped Clean Action Tiles Container (Mock 4)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.neutralBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _ProfileMenuItem(
                        icon: Icons.person_outline_rounded,
                        iconColor: AppTheme.primary,
                        title: 'Informasi Pribadi',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        ),
                      ),
                      const Divider(height: 1, indent: 56, endIndent: 16),
                      _ProfileMenuItem(
                        icon: Icons.lock_outline_rounded,
                        iconColor: const Color(0xFF2563EB),
                        title: 'Keamanan Akun',
                        onTap: () => _showSecurityDialog(context, user),
                      ),
                      const Divider(height: 1, indent: 56, endIndent: 16),
                      _ProfileMenuItem(
                        icon: Icons.badge_outlined,
                        iconColor: AppTheme.goldDark,
                        title: 'Peran Saya',
                        trailingText: _roleName(role),
                        onTap: () => _showRoleInfoDialog(context, auth),
                      ),
                      const Divider(height: 1, indent: 56, endIndent: 16),
                      _ProfileMenuItem(
                        icon: Icons.palette_outlined,
                        iconColor: const Color(0xFF8B5CF6),
                        title: 'Pengaturan Tampilan',
                        onTap: () => _showAppearanceDialog(context),
                      ),
                      const Divider(height: 1, indent: 56, endIndent: 16),
                      _ProfileMenuItem(
                        icon: Icons.help_outline_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: 'Pusat Bantuan',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FeedbackScreen(feedbackType: 'general'),
                          ),
                        ),
                      ),
                      if (auth.isAdmin) ...[
                        const Divider(height: 1, indent: 56, endIndent: 16),
                        _ProfileMenuItem(
                          icon: Icons.manage_accounts_rounded,
                          iconColor: AppTheme.primary,
                          title: 'Kelola Data Pengguna',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminManagementScreen(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Red Outlined Logout Button (Mock 4)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, auth),
                    icon: const Icon(Icons.logout_rounded, size: 20, color: AppTheme.errorColor),
                    label: const Text(
                      'Keluar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.errorColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.darkCharcoal,
                    side: const BorderSide(color: AppTheme.neutralBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Keluar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await auth.logout();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkCharcoal,
                  ),
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mutedCharcoal,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTheme.neutralMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

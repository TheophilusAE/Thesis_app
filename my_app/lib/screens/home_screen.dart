import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/feedback_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/role_switcher.dart';
import 'admin_management_screen.dart';
import 'admin_attendance_monitoring_screen.dart';
import 'admin_substitution_review_screen.dart';
import 'attendance_confirmation_screen.dart';
import 'bible_screen.dart';
import 'devotional_screen.dart';
import 'feedback_management_screen.dart';
import 'feedback_screen.dart';
import 'member_card_screen.dart';
import 'event_list_screen.dart';
import 'pelayan_management_screen.dart';
import 'profile_screen.dart';
import 'quest_screen.dart';
import 'role_management_screen.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  String _lastRole = '';

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
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: _dests(role),
            height: 68,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
      decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Role badge + switcher
                  if (userRoles.length > 1) ...[
                    RoleSwitcher(),
                    const SizedBox(width: 4),
                  ] else
                    _RoleBadge(label: roleLabel),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  const _RoleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      )),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey[600],
                      )),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 22),
          ],
        ),
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
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
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

    final users = await auth.getAllUsers();
    await fbProvider.loadAllFeedback();
    final feedback = fbProvider.allFeedback;

    final pending = users.where((u) => u.membershipStatus == 'pending').length;
    final avg = feedback.isEmpty
        ? 0.0
        : feedback.fold<int>(0, (s, f) => s + f.rating) / feedback.length;

    return {
      'users': users.length,
      'pending': pending,
      'feedback': feedback.length,
      'avgRating': avg,
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
            subtitle: 'Selamat datang di Panel Admin',
            roleLabel: 'Admin',
            userRoles: auth.userRoles,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                      tooltip: 'Segarkan',
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
                      childAspectRatio: 1.25,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _StatCard(
                          label: 'Total Pengguna',
                          value: '${d['users'] ?? 0}',
                          icon: Icons.people_rounded,
                          color: const Color(0xFF1E3A5F),
                        ),
                        _StatCard(
                          label: 'Menunggu Persetujuan',
                          value: '${d['pending'] ?? 0}',
                          icon: Icons.hourglass_bottom_rounded,
                          color: Colors.orange,
                        ),
                        _StatCard(
                          label: 'Total Feedback',
                          value: '${d['feedback'] ?? 0}',
                          icon: Icons.message_rounded,
                          color: Colors.purple,
                        ),
                        _StatCard(
                          label: 'Rating Rata-rata',
                          value:
                              '${((d['avgRating'] ?? 0.0) as double).toStringAsFixed(1)}/5',
                          icon: Icons.star_rounded,
                          color: Colors.amber,
                        ),
                      ],
                    );
                  },
                ),
                const _SectionTitle('Aksi Cepat'),
                _NavCard(
                  icon: Icons.person_add_rounded,
                  title: 'Kelola Pengguna',
                  subtitle: 'Tambah, edit, dan verifikasi anggota',
                  color: const Color(0xFF1E3A5F),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminManagementScreen())),
                ),
                _NavCard(
                  icon: Icons.people_alt_rounded,
                  title: 'Kelola Pelayan',
                  subtitle: 'Manajemen data pelayan gereja',
                  color: Colors.teal,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PelayaniManagementScreen())),
                ),
                _NavCard(
                  icon: Icons.message_rounded,
                  title: 'Lihat Feedback',
                  subtitle: 'Tinjau feedback jemaat',
                  color: Colors.purple,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FeedbackManagementScreen())),
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
            greeting: 'Manajemen',
            name: user?.name ?? 'Admin',
            subtitle: 'Kelola data pengguna dan pelayan',
            roleLabel: 'Admin',
            userRoles: auth.userRoles,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Data Pengguna'),
                _NavCard(
                  icon: Icons.person_rounded,
                  title: 'Manajemen Pengguna',
                  subtitle: 'Lihat, edit, dan verifikasi akun jemaat',
                  color: const Color(0xFF1E3A5F),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminManagementScreen())),
                ),
                _NavCard(
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Manajemen Role',
                  subtitle: 'Atur hak akses pengguna',
                  color: Colors.orange,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RoleManagementScreen())),
                ),
                const _SectionTitle('Data Pelayan'),
                _NavCard(
                  icon: Icons.people_alt_rounded,
                  title: 'Manajemen Pelayan',
                  subtitle: 'Kelola data pelayan gereja',
                  color: Colors.teal,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PelayaniManagementScreen())),
                ),
                const _SectionTitle('Feedback'),
                _NavCard(
                  icon: Icons.feedback_rounded,
                  title: 'Tinjau Feedback',
                  subtitle: 'Baca dan kelola feedback jemaat',
                  color: Colors.purple,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FeedbackManagementScreen())),
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
            greeting: 'Jadwal & Kehadiran',
            name: user?.name ?? 'Admin',
            subtitle: 'Kelola jadwal pelayanan dan kehadiran',
            roleLabel: 'Admin',
            userRoles: auth.userRoles,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Jadwal'),
                _NavCard(
                  icon: Icons.calendar_today_rounded,
                  title: 'Jadwal Pelayanan',
                  subtitle: 'Atur jadwal tugas pelayan',
                  color: const Color(0xFF1E3A5F),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const ServiceScheduleManagementScreen())),
                ),
                _NavCard(
                  icon: Icons.school_rounded,
                  title: 'Jadwal Latihan',
                  subtitle: 'Kelola jadwal pelatihan pelayan',
                  color: Colors.teal,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const TrainingScheduleManagementScreen())),
                ),
                const _SectionTitle('Monitoring'),
                _NavCard(
                  icon: Icons.fact_check_rounded,
                  title: 'Monitoring Kehadiran',
                  subtitle: 'Pantau kehadiran pelayan',
                  color: Colors.green,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AdminAttendanceMonitoringScreen())),
                ),
                _NavCard(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Permintaan Penggantian',
                  subtitle: 'Tinjau pengajuan penggantian tugas',
                  color: Colors.orange,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AdminSubstitutionReviewScreen())),
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
            subtitle: 'Lihat jadwal dan tugasmu',
            roleLabel: 'Pelayan',
            userRoles: auth.userRoles,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Jadwal & Tugas'),
                _NavCard(
                  icon: Icons.calendar_today_rounded,
                  title: 'Jadwal Pelayananku',
                  subtitle: 'Lihat jadwal tugas pelayanan',
                  color: const Color(0xFF1E3A5F),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const ServiceScheduleManagementScreen())),
                ),
                _NavCard(
                  icon: Icons.school_rounded,
                  title: 'Jadwal Latihan',
                  subtitle: 'Lihat jadwal pelatihan',
                  color: Colors.teal,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const TrainingScheduleManagementScreen())),
                ),
                const _SectionTitle('Kehadiran'),
                _NavCard(
                  icon: Icons.how_to_reg_rounded,
                  title: 'Konfirmasi Kehadiran',
                  subtitle: 'Konfirmasi kehadiranmu untuk jadwal mendatang',
                  color: Colors.green,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AttendanceConfirmationScreen())),
                ),
                _NavCard(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Ajukan Penggantian',
                  subtitle: 'Minta penggantian jadwal tugas',
                  color: Colors.orange,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const SubstitutionRequestScreen())),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PelayananJadwalTab extends StatelessWidget {
  const _PelayananJadwalTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _GradientHeader(
            greeting: 'Jadwalku',
            name: user?.name ?? 'Pelayan',
            subtitle: 'Semua jadwal pelayanan dan latihan',
            roleLabel: 'Pelayan',
            userRoles: auth.userRoles,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Jadwal Pelayanan'),
                _NavCard(
                  icon: Icons.event_rounded,
                  title: 'Jadwal Ibadah',
                  subtitle: 'Lihat jadwal pelayanan ibadah',
                  color: const Color(0xFF1E3A5F),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const ServiceScheduleManagementScreen())),
                ),
                const _SectionTitle('Jadwal Latihan'),
                _NavCard(
                  icon: Icons.school_rounded,
                  title: 'Latihan & Pembekalan',
                  subtitle: 'Lihat jadwal pelatihan tim pelayan',
                  color: Colors.teal,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const TrainingScheduleManagementScreen())),
                ),
              ],
            ),
          ),
        ),
      ],
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
            greeting: 'Kehadiran',
            name: user?.name ?? 'Pelayan',
            subtitle: 'Konfirmasi dan kelola kehadiranmu',
            roleLabel: 'Pelayan',
            userRoles: auth.userRoles,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Konfirmasi Kehadiran'),
                _NavCard(
                  icon: Icons.how_to_reg_rounded,
                  title: 'Konfirmasi Kehadiran',
                  subtitle: 'Konfirmasi hadir atau tidak untuk jadwal',
                  color: Colors.green,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AttendanceConfirmationScreen())),
                ),
                const _SectionTitle('Penggantian Tugas'),
                _NavCard(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Ajukan Penggantian',
                  subtitle: 'Ajukan permintaan pergantian jadwal',
                  color: Colors.orange,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const SubstitutionRequestScreen())),
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

class _JemaatBeranda extends StatelessWidget {
  const _JemaatBeranda();

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
                // ── Banner Carousel ──────────────────────────
                const SizedBox(height: 18),
                const _BannerCarousel(),
                const SizedBox(height: 22),

                // ── Quick Actions ────────────────────────────
                const _HomeQuickActionsRow(),
                const SizedBox(height: 24),

                // ── Verse of the Day ─────────────────────────
                const _SectionTitle('Ayat Hari Ini'),
                const SizedBox(height: 10),
                const _DailyVerseCard(),
                const SizedBox(height: 24),

                // ── Feature Grid ─────────────────────────────
                const _SectionTitle('Fitur Utama'),
                const SizedBox(height: 10),
                _FeatureGrid(
                  features: [
                    _Feature(
                      icon: Icons.menu_book_rounded,
                      label: 'Alkitab',
                      color: const Color(0xFF1E3A5F),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const BibleScreen())),
                    ),
                    _Feature(
                      icon: Icons.credit_card_rounded,
                      label: 'Kartu Jemaat',
                      color: const Color(0xFF0D9488),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const MemberCardScreen())),
                    ),
                    _Feature(
                      icon: Icons.auto_stories_rounded,
                      label: 'Renungan',
                      color: const Color(0xFF0D9488),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const DevotionalScreen())),
                    ),
                    _Feature(
                      icon: Icons.military_tech_rounded,
                      label: 'Quest',
                      color: const Color(0xFFD4A017),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const QuestScreen())),
                    ),
                    _Feature(
                      icon: Icons.feedback_rounded,
                      label: 'Feedback',
                      color: const Color(0xFF7C3AED),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const FeedbackScreen(feedbackType: 'general'))),
                    ),
                    _Feature(
                      icon: Icons.event_available_rounded,
                      label: 'Daftar Event',
                      color: const Color(0xFF1D4ED8),
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const EventListScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Jadwal Ibadah ─────────────────────────────
                const _SectionTitle('Jadwal Ibadah'),
                const SizedBox(height: 10),
                const _ServiceScheduleStrip(),
                const SizedBox(height: 24),

                // ── Pengumuman ────────────────────────────────
                const _SectionTitle('Pengumuman'),
                const SizedBox(height: 10),
                const _AnnouncementsList(),
              ],
            ),
          ),
        ),
      ],
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
        colors: [Color(0xFF1E3A5F), Color(0xFF2C5282)],
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
        colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
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
        colors: [Color(0xFFD4A017), Color(0xFFB8860B)],
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
                color: active ? const Color(0xFF1E3A5F) : const Color(0xFFCBD5E1),
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
// HOME QUICK ACTIONS ROW
// ─────────────────────────────────────────────────────────────────────────────

class _HomeQuickActionsRow extends StatelessWidget {
  const _HomeQuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QBtn(
            icon: Icons.volunteer_activism_rounded,
            label: 'Doa',
            color: const Color(0xFFD4A017),
            onTap: () => _showOfferingSheet(context, prayer: true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QBtn(
            icon: Icons.favorite_rounded,
            label: 'Persembahan',
            color: const Color(0xFF1E3A5F),
            onTap: () => _showOfferingSheet(context, prayer: false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QBtn(
            icon: Icons.info_outline_rounded,
            label: 'Info Gereja',
            color: const Color(0xFF60A5FA),
            onTap: () => _showInfoSheet(context),
          ),
        ),
      ],
    );
  }

  void _showOfferingSheet(BuildContext context, {required bool prayer}) {
    if (prayer) {
      final ctrl = TextEditingController();
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Permintaan Doa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Pokok Doa',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A017),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Permintaan doa diterima. Tuhan memberkati!'),
                        backgroundColor: const Color(0xFFD4A017),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  child: const Text('Kirim'),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Persembahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  '"Setiap orang memberikan menurut kerelaan hatinya" — 2 Korintus 9:7',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                _OfferingRow(icon: Icons.qr_code_2_rounded, title: 'QRIS', subtitle: 'Scan kode QR', color: const Color(0xFF1E3A5F)),
                const SizedBox(height: 8),
                _OfferingRow(icon: Icons.account_balance_rounded, title: 'Transfer Bank', subtitle: 'BCA • 1234567890 • a.n. Gereja', color: const Color(0xFF0D9488)),
                const SizedBox(height: 8),
                _OfferingRow(icon: Icons.church_rounded, title: 'Langsung', subtitle: 'Kotak persembahan saat ibadah', color: const Color(0xFFD4A017)),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _showInfoSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Info Gereja', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              _InfoRow(icon: Icons.location_on_rounded, label: 'Alamat', value: 'Jl. Gereja No. 1, Kota Anda', color: const Color(0xFF1E3A5F)),
              _InfoRow(icon: Icons.phone_rounded, label: 'Telepon', value: '+62 xxx xxxx xxxx', color: const Color(0xFF0D9488)),
              _InfoRow(icon: Icons.email_rounded, label: 'Email', value: 'info@gereja.com', color: const Color(0xFF60A5FA)),
              _InfoRow(icon: Icons.access_time_rounded, label: 'Ibadah Minggu', value: '07:00 & 09:30 WIB', color: const Color(0xFFD4A017)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.22)),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _OfferingRow({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color, size: 18),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DAILY VERSE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _DailyVerseCard extends StatelessWidget {
  const _DailyVerseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2C5282)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10, top: -10,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A017).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.format_quote_rounded, color: Color(0xFFD4A017), size: 16),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A017).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD4A017).withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'Yohanes 3:16',
                      style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '"Karena begitu besar kasih Allah akan dunia ini, sehingga Ia telah mengaruniakan Anak-Nya yang tunggal..."',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Baca selengkapnya →',
                    style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w500),
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

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE SCHEDULE STRIP
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceScheduleStrip extends StatelessWidget {
  const _ServiceScheduleStrip();

  @override
  Widget build(BuildContext context) {
    const services = [
      (day: 'Minggu', time: '07:00', name: 'Kebaktian Umum I', theme: 'Kasih Karunia Allah'),
      (day: 'Minggu', time: '09:30', name: 'Kebaktian Umum II', theme: 'Hidup dalam Roh'),
      (day: 'Rabu', time: '19:00', name: 'Kebaktian Doa', theme: 'Doa & Penyembahan'),
      (day: 'Jumat', time: '19:00', name: 'Kebaktian Pemuda', theme: 'Generasi Berdampak'),
    ];

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 2),
        itemCount: services.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final s = services[i];
          return Container(
            width: 162,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8F0F8)),
              boxShadow: [BoxShadow(color: const Color(0xFF1E3A5F).withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
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
                        color: const Color(0xFF1E3A5F).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(s.day, style: const TextStyle(color: Color(0xFF1E3A5F), fontSize: 10.5, fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4A017).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(s.time, style: const TextStyle(color: Color(0xFFD4A017), fontSize: 10.5, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(s.name, style: const TextStyle(color: Color(0xFF1F2937), fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(s.theme, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
      ),
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
      (title: 'Retreat Tahunan Gereja 2025', desc: 'Daftarkan diri Anda untuk retreat di Puncak, 15–17 Agustus 2025.', date: '15–17 Agt', category: 'Event', color: Color(0xFFD4A017)),
      (title: 'Pelayanan Sosial: Bakti Panti', desc: 'Bergabung melayani di panti asuhan terdekat. Pendaftaran relawan dibuka.', date: '25 Agustus', category: 'Sosial', color: Color(0xFF0D9488)),
      (title: 'Kelas Pendalaman Alkitab', desc: 'Kelas PA baru setiap Sabtu pukul 10:00. Terbuka untuk seluruh jemaat.', date: 'Setiap Sabtu', category: 'Belajar', color: Color(0xFF1E3A5F)),
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

class _Feature {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Feature({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _FeatureGrid extends StatelessWidget {
  final List<_Feature> features;
  const _FeatureGrid({required this.features});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 0.95,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: features
          .map((f) => _FeatureTile(
                icon: f.icon,
                label: f.label,
                color: f.color,
                onTap: f.onTap,
              ))
          .toList(),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.18), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
            subtitle: 'Fitur rohani dan layanan jemaat',
            roleLabel: 'Jemaat',
            userRoles: auth.userRoles,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Pengembangan Rohani'),
                _NavCard(
                  icon: Icons.auto_stories_rounded,
                  title: 'Renungan Harian',
                  subtitle: 'Baca renungan dan perenungan firman',
                  color: Color(0xFF0D9488),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const DevotionalScreen())),
                ),
                _NavCard(
                  icon: Icons.military_tech_rounded,
                  title: 'Quest Baca',
                  subtitle: 'Tantangan membaca Alkitab harian',
                  color: Color(0xFFD4A017),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const QuestScreen())),
                ),
                const _SectionTitle('Keanggotaan'),
                _NavCard(
                  icon: Icons.credit_card_rounded,
                  title: 'Kartu Jemaat',
                  subtitle: 'Lihat dan bagikan kartu identitas jemaat',
                  color: Color(0xFF1E3A5F),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MemberCardScreen())),
                ),
                const _SectionTitle('Layanan'),
                _NavCard(
                  icon: Icons.event_available_rounded,
                  title: 'Daftar Event',
                  subtitle: 'Natal, Paskah, Ibadah Padang & lainnya',
                  color: Color(0xFF1D4ED8),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const EventListScreen())),
                ),
                const _SectionTitle('Masukan'),
                _NavCard(
                  icon: Icons.feedback_rounded,
                  title: 'Kirim Feedback',
                  subtitle: 'Berikan masukan untuk gereja kita',
                  color: Color(0xFF7C3AED),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FeedbackScreen(feedbackType: 'general'))),
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
// SHARED PROFILE TAB
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final role = auth.currentDisplayRole;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _GradientHeader(
            greeting: 'Profil Saya',
            name: user?.name ?? '',
            subtitle: user?.email ?? '',
            roleLabel: _roleName(role),
            userRoles: auth.userRoles,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Info card
                _ProfileInfoCard(user: user),
                const SizedBox(height: 20),
                // Edit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit Profil'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout_rounded, size: 18,
                        color: Colors.red),
                    label: const Text('Keluar',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                    onPressed: () => _confirmLogout(context, auth),
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
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await auth.logout();
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final User? user;
  const _ProfileInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _ProfileRow(
            icon: Icons.person_rounded,
            label: 'Nama',
            value: user?.name ?? '-',
          ),
          const Divider(height: 24),
          _ProfileRow(
            icon: Icons.email_rounded,
            label: 'Email',
            value: user?.email ?? '-',
          ),
          const Divider(height: 24),
          _ProfileRow(
            icon: Icons.phone_rounded,
            label: 'Telepon',
            value: user?.phone.isNotEmpty == true ? user!.phone : '-',
          ),
          const Divider(height: 24),
          _ProfileRow(
            icon: Icons.verified_user_rounded,
            label: 'Status',
            value: _statusLabel(user?.membershipStatus),
          ),
          if (user?.address?.isNotEmpty == true) ...[
            const Divider(height: 24),
            _ProfileRow(
              icon: Icons.home_rounded,
              label: 'Alamat',
              value: user!.address!,
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'active': return 'Aktif';
      case 'pending': return 'Menunggu Verifikasi';
      case 'rejected': return 'Ditolak';
      default: return '-';
    }
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1E3A5F)),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A))),
        ),
      ],
    );
  }
}

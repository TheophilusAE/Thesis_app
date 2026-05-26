import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/feedback_service.dart';
import 'admin_management_screen.dart';
import 'feedback_management_screen.dart';
import '../widgets/role_switcher.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const AdminDashboard(),
      const AdminManagementScreen(),
      const FeedbackManagementScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primaryContainer,
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
      bottomNavigationBar: Material(
        elevation: 8,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.95),
                colorScheme.primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: _currentIndex,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withValues(alpha: 0.6),
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_rounded),
                label: 'Kelola Data',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.message_rounded),
                label: 'Feedback',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FeedbackService _feedbackService = FeedbackService();
  late Future<Map<String, dynamic>> _dashboardStatsFuture;

  @override
  void initState() {
    super.initState();
    _dashboardStatsFuture = _buildDashboardStats();
  }

  void _refreshData() {
    setState(() {
      _dashboardStatsFuture = _buildDashboardStats();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data diperbarui'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Enhanced Header
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.9),
                        colorScheme.primary.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, _) {
                                final user = authProvider.currentUser;
                                return PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'settings') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Pengaturan akan segera hadir'),
                                        ),
                                      );
                                    } else if (value == 'logout') {
                                      // Show logout confirmation
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Logout'),
                                          content: const Text('Apakah Anda yakin ingin keluar?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Batal'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                authProvider.logout();
                                              },
                                              child: const Text('Logout'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    PopupMenuItem<String>(
                                      value: 'profile',
                                      enabled: false,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user?.name ?? 'Admin',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            user?.email ?? 'admin@gereja.com',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem<String>(
                                      value: 'settings',
                                      child: Row(
                                        children: [
                                          Icon(Icons.settings_rounded, size: 20),
                                          SizedBox(width: 12),
                                          Text('Pengaturan'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'logout',
                                      child: Row(
                                        children: [
                                          Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                                          SizedBox(width: 12),
                                          Text('Logout', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    child: Text(
                                      user?.name.substring(0, 1).toUpperCase() ?? 'A',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Consumer<AuthProvider>(
                                builder: (context, authProvider, _) {
                                  final user = authProvider.currentUser;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selamat datang,',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.9),
                                        ),
                                      ),
                                      Text(
                                        user?.name ?? 'Admin',
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                              tooltip: 'Segarkan data',
                              onPressed: _refreshData,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats Section
                  FutureBuilder<Map<String, dynamic>>(
                    future: _dashboardStatsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                            ),
                          ),
                        );
                      }

                      final stats = snapshot.data ?? {};

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Stats Row 1
                          Row(
                            children: [
                              Expanded(
                                child: _EnhancedStatsCard(
                                  title: 'Total Pengguna',
                                  value: (stats['totalUsers'] ?? 0).toString(),
                                  icon: Icons.people_rounded,
                                  color: Colors.blue,
                                  trend: '+12% bulan ini',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _EnhancedStatsCard(
                                  title: 'Menunggu Approval',
                                  value: (stats['pendingUsers'] ?? 0).toString(),
                                  icon: Icons.hourglass_bottom_rounded,
                                  color: Colors.orange,
                                  trend: 'Butuh tindakan',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Quick Stats Row 2
                          Row(
                            children: [
                              Expanded(
                                child: _EnhancedStatsCard(
                                  title: 'Total Feedback',
                                  value: (stats['totalFeedback'] ?? 0).toString(),
                                  icon: Icons.message_rounded,
                                  color: Colors.purple,
                                  trend: 'Pekan ini',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _EnhancedStatsCard(
                                  title: 'Rating Rata-rata',
                                  value:
                                      '${((stats['avgFeedbackRating'] ?? 0.0) as double).toStringAsFixed(1)}/5',
                                  icon: Icons.star_rounded,
                                  color: Colors.amber,
                                  trend: 'Sangat baik',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Feedback Breakdown Section
                          Text(
                            'Analisis Feedback',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FutureBuilder<Map<String, int>>(
                            future: _buildFeedbackBreakdown(),
                            builder: (context, breakdownSnapshot) {
                              if (breakdownSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final breakdown = breakdownSnapshot.data ?? {};
                              final total = breakdown.values
                                  .fold<int>(0, (sum, v) => sum + v);

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _FeedbackTypeRow(
                                      type: 'Event',
                                      count: breakdown['event'] ?? 0,
                                      total: total,
                                      color: Colors.blue,
                                      icon: Icons.event_rounded,
                                    ),
                                    const SizedBox(height: 12),
                                    _FeedbackTypeRow(
                                      type: 'Fasilitas',
                                      count: breakdown['facility'] ?? 0,
                                      total: total,
                                      color: Colors.green,
                                      icon: Icons.home_rounded,
                                    ),
                                    const SizedBox(height: 12),
                                    _FeedbackTypeRow(
                                      type: 'Hospitality',
                                      count: breakdown['hospitality'] ?? 0,
                                      total: total,
                                      color: Colors.pink,
                                      icon: Icons.handshake_rounded,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 28),

                          // Quick Actions
                          Text(
                            'Aksi Cepat',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 1.15,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            children: [
                              _AdminActionCard(
                                icon: Icons.person_add_rounded,
                                title: 'Kelola Pengguna',
                                subtitle: 'Tambah/edit data user',
                                color: Colors.blue,
                                onTap: () {
                                  // Navigate to Kelola Data tab
                                  final adminHomeState = context.findAncestorStateOfType<_AdminHomeScreenState>();
                                  adminHomeState?.setState(() {
                                    adminHomeState._currentIndex = 1;
                                  });
                                },
                              ),
                              _AdminActionCard(
                                icon: Icons.message_rounded,
                                title: 'Review Feedback',
                                subtitle: 'Baca feedback pengguna',
                                color: Colors.purple,
                                onTap: () {
                                  // Navigate to Feedback tab
                                  final adminHomeState = context.findAncestorStateOfType<_AdminHomeScreenState>();
                                  adminHomeState?.setState(() {
                                    adminHomeState._currentIndex = 2;
                                  });
                                },
                              ),
                              _AdminActionCard(
                                icon: Icons.menu_book_rounded,
                                title: 'Kelola Renungan',
                                subtitle: 'Tambah renungan baru',
                                color: Colors.green,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Fitur Kelola Renungan akan segera hadir'),
                                    ),
                                  );
                                },
                              ),
                              _AdminActionCard(
                                icon: Icons.task_alt_rounded,
                                title: 'Kelola Quest',
                                subtitle: 'Atur quest baca',
                                color: Colors.teal,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Fitur Kelola Quest akan segera hadir'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _buildDashboardStats() async {
    final provider = context.read<AuthProvider>();
    final allUsers = await provider.getAllUsers();
    final pendingUsers =
        allUsers.where((u) => u.membershipStatus == 'pending').length;
    final allFeedback = await _feedbackService.getAllFeedback();

    double avgRating = 0;
    if (allFeedback.isNotEmpty) {
      final totalRating =
          allFeedback.fold<int>(0, (sum, f) => sum + f.rating);
      avgRating = totalRating / allFeedback.length;
    }

    return {
      'totalUsers': allUsers.length,
      'pendingUsers': pendingUsers,
      'totalFeedback': allFeedback.length,
      'avgFeedbackRating': avgRating,
    };
  }

  Future<Map<String, int>> _buildFeedbackBreakdown() async {
    final feedback = await _feedbackService.getAllFeedback();
    final eventFeedback =
        feedback.where((f) => f.feedbackType == 'event').length;
    final facilityFeedback =
        feedback.where((f) => f.feedbackType == 'facility').length;
    final hospitalityFeedback =
        feedback.where((f) => f.feedbackType == 'hospitality').length;

    return {
      'event': eventFeedback,
      'facility': facilityFeedback,
      'hospitality': hospitalityFeedback,
    };
  }
}

class _EnhancedStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _EnhancedStatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            color.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              trend,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackTypeRow extends StatelessWidget {
  final String type;
  final int count;
  final int total;
  final Color color;
  final IconData icon;

  const _FeedbackTypeRow({
    required this.type,
    required this.count,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? count / total : 0,
                  minHeight: 6,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              '$percentage%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AdminActionCard> createState() => _AdminActionCardState();
}

class _AdminActionCardState extends State<_AdminActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                widget.color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.color.withValues(alpha: 0.2),
                            widget.color.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

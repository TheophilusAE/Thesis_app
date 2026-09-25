import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reading_quest.dart';
import '../providers/auth_provider.dart';
import '../providers/quest_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_skeleton.dart';
import '../widgets/common/app_status_badge.dart';

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  int _filterIndex = 0; // 0: Semua, 1: Belum Selesai, 2: Selesai
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuestProvider>().loadReadingPlan();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text('Quest Baca Alkitab Setahun'),
      ),
      body: Consumer<QuestProvider>(
        builder: (context, questProvider, child) {
          if (questProvider.isLoading) {
            return _buildLoadingSkeleton();
          }

          var filteredList = questProvider.readingPlan;
          if (_filterIndex == 1) {
            filteredList = filteredList.where((q) => !q.isCompleted).toList();
          } else if (_filterIndex == 2) {
            filteredList = filteredList.where((q) => q.isCompleted).toList();
          }

          if (_searchQuery.isNotEmpty) {
            final dayNumber = int.tryParse(_searchQuery.trim());
            if (dayNumber != null) {
              filteredList = filteredList.where((q) => q.day == dayNumber).toList();
            } else {
              filteredList = filteredList.where((q) {
                return q.readings.any(
                  (r) => r.displayText.toLowerCase().contains(_searchQuery.toLowerCase()),
                );
              }).toList();
            }
          }

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () => questProvider.loadReadingPlan(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                // Admin Settings Card (if Admin)
                _buildAdminSection(context, questProvider),

                // Progress Hero Header Card
                _buildProgressHeader(questProvider),

                const SizedBox(height: 16),

                // Filter & Search Controls
                _buildFilterBar(),

                const SizedBox(height: 16),

                // Quest List Items
                if (filteredList.isEmpty)
                  AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Tidak Ada Bacaan',
                    description: _searchQuery.isNotEmpty
                        ? 'Tidak ditemukan bacaan untuk "$_searchQuery".'
                        : (_filterIndex == 1
                            ? 'Luar biasa! Semua bacaan telah Anda selesaikan.'
                            : 'Belum ada bacaan yang selesai.'),
                  )
                else
                  ...filteredList.map((quest) => _buildQuestCard(context, quest, questProvider)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminSection(BuildContext context, QuestProvider questProvider) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.currentDisplayRole != 'admin') {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppCard(
            borderColor: AppTheme.gold.withValues(alpha: 0.5),
            color: const Color(0xFFFFFBEB),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.goldDark, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Pengaturan Target (Admin)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkCharcoal,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.goldLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${questProvider.dailyTarget} pasal/hari',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.goldDark,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tentukan target jumlah pasal harian yang direkomendasikan untuk jemaat:',
                  style: TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primary,
                    inactiveTrackColor: AppTheme.neutralLight,
                    thumbColor: AppTheme.primary,
                  ),
                  child: Slider(
                    value: questProvider.dailyTarget.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${questProvider.dailyTarget}',
                    onChanged: (value) {
                      questProvider.updateDailyTarget(value.round());
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

  Widget _buildProgressHeader(QuestProvider questProvider) {
    final percent = (questProvider.progress * 100).clamp(0.0, 100.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.burgundy,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Hari Selesai',
                  value: '${questProvider.completedDays.length}/365',
                  accentColor: Colors.white,
                ),
              ),
              Container(
                height: 48,
                width: 1,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Streak Disiplin',
                  value: '${questProvider.streak} Hari',
                  accentColor: AppTheme.goldLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kemajuan Membaca',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${percent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: AppTheme.goldLight,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: questProvider.progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: accentColor, size: 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: accentColor,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Column(
      children: [
        // Search by day number or book name
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.neutralBorder),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari hari atau kitab (cth: 12, Yohanes)...',
              hintStyle: const TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.neutralMedium, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Segmented filter chips
        Row(
          children: [
            _buildFilterChip('Semua', 0),
            const SizedBox(width: 8),
            _buildFilterChip('Belum Selesai', 1),
            const SizedBox(width: 8),
            _buildFilterChip('Selesai', 2),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _filterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.neutralBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.darkCharcoal,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestCard(
    BuildContext context,
    ReadingQuest quest,
    QuestProvider questProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        borderColor: quest.isCompleted ? AppTheme.emerald.withValues(alpha: 0.3) : AppTheme.neutralBorder,
        color: quest.isCompleted ? const Color(0xFFF0FDF4) : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: quest.isCompleted
                        ? AppTheme.emerald.withValues(alpha: 0.15)
                        : AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Hari ${quest.day}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: quest.isCompleted ? AppTheme.emerald : AppTheme.primaryDark,
                    ),
                  ),
                ),
                const Spacer(),
                if (quest.isCompleted)
                  const AppStatusBadge(
                    label: 'Selesai',
                    status: 'completed',
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => _confirmMarkCompleted(context, quest, questProvider),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Tandai Selesai'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Readings list
            ...quest.readings.map(
              (reading) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      quest.isCompleted ? Icons.check_circle_outline_rounded : Icons.bookmark_border_rounded,
                      size: 18,
                      color: quest.isCompleted ? AppTheme.emerald : AppTheme.goldDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reading.displayText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: quest.isCompleted ? AppTheme.neutralMedium : AppTheme.darkCharcoal,
                          decoration: quest.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
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

  Future<void> _confirmMarkCompleted(
    BuildContext context,
    ReadingQuest quest,
    QuestProvider questProvider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: AppTheme.primary),
            SizedBox(width: 10),
            Text('Tandai Selesai'),
          ],
        ),
        content: Text(
          'Tandai bacaan Hari ${quest.day} (${quest.readings.map((r) => r.displayText).join(", ")}) sebagai selesai?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: AppTheme.neutralMedium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Selesai'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await questProvider.markDayCompleted(quest.day);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Puji Tuhan! Bacaan Hari ${quest.day} selesai dibaca! 🎉'),
          backgroundColor: AppTheme.emerald,
        ),
      );
    }
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: const [
          AppSkeleton(height: 180, borderRadius: AppTheme.cardRadius),
          SizedBox(height: 16),
          AppSkeleton(height: 46, borderRadius: AppTheme.cardRadius),
          SizedBox(height: 16),
          AppSkeleton(height: 90, borderRadius: AppTheme.cardRadius),
          SizedBox(height: 12),
          AppSkeleton(height: 90, borderRadius: AppTheme.cardRadius),
          SizedBox(height: 12),
          AppSkeleton(height: 90, borderRadius: AppTheme.cardRadius),
        ],
      ),
    );
  }
}

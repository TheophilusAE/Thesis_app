import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/devotional.dart';
import '../services/devotional_service.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_error_state.dart';
import '../widgets/common/app_skeleton.dart';

class DevotionalScreen extends StatefulWidget {
  const DevotionalScreen({super.key});

  @override
  State<DevotionalScreen> createState() => _DevotionalScreenState();
}

class _DevotionalScreenState extends State<DevotionalScreen> {
  final DevotionalService _devotionalService = DevotionalService();
  late Future<Devotional> _todayFuture;
  Devotional? _activeDevotional;
  Devotional? _todayDevotional;
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _todayFuture = _devotionalService.getTodaysDevotional();
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(14.0, 24.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: const Text('Renungan Harian'),
        actions: [
          IconButton(
            tooltip: 'Kecilkan teks',
            icon: const Icon(Icons.text_decrease_rounded),
            onPressed: _fontSize > 14.0 ? () => _changeFontSize(-2.0) : null,
          ),
          IconButton(
            tooltip: 'Besarkan teks',
            icon: const Icon(Icons.text_increase_rounded),
            onPressed: _fontSize < 24.0 ? () => _changeFontSize(2.0) : null,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<Devotional>(
        future: _todayFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingSkeleton();
          }

          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Gagal Memuat Renungan',
              message: 'Terjadi kendala saat mengambil renungan hari ini. Silakan coba kembali.',
              onRetry: () {
                setState(() {
                  _loadData();
                });
              },
            );
          }

          if (!snapshot.hasData) {
            return const AppEmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Belum Ada Renungan',
              description: 'Renungan untuk hari ini belum tersedia.',
            );
          }

          _todayDevotional ??= snapshot.data!;
          final devotional = _activeDevotional ?? _todayDevotional!;
          final isReadingPast = _activeDevotional != null && _activeDevotional!.id != _todayDevotional!.id;

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async {
              setState(() {
                _loadData();
                _activeDevotional = null;
                _todayDevotional = null;
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isReadingPast)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history_rounded, color: AppTheme.primary, size: 20),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Membaca arsip renungan lampau',
                                style: TextStyle(
                                  color: AppTheme.primaryDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _activeDevotional = _todayDevotional;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Ke Hari Ini',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  _buildHeaderCard(context, devotional),

                  const SizedBox(height: 16),

                  _buildScriptureCard(context, devotional),

                  const SizedBox(height: 20),

                  _buildContentCard(context, devotional),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Bagikan',
                          icon: Icons.share_outlined,
                          variant: AppButtonVariant.outline,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fitur berbagi renungan akan segera hadir'),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Simpan',
                          icon: Icons.bookmark_border_rounded,
                          variant: AppButtonVariant.primary,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Renungan disimpan ke daftar bacaan'),
                                backgroundColor: AppTheme.primary,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  _buildHistorySection(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Devotional devotional) {
    final formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(devotional.date);

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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppTheme.goldLight,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            devotional.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          if (devotional.author != null && devotional.author!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  color: AppTheme.goldLight,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Oleh ${devotional.author}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScriptureCard(BuildContext context, Devotional devotional) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35), width: 1.5),
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
                  color: AppTheme.goldLight.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.format_quote_rounded,
                  color: AppTheme.goldDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                devotional.verseReference,
                style: const TextStyle(
                  color: AppTheme.goldDark,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            devotional.verse,
            style: TextStyle(
              fontSize: _fontSize,
              fontStyle: FontStyle.italic,
              color: AppTheme.darkCharcoal,
              height: 1.65,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, Devotional devotional) {
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Renungan Firman',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkCharcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            devotional.content,
            style: TextStyle(
              fontSize: _fontSize,
              height: 1.8,
              color: AppTheme.darkCharcoal.withValues(alpha: 0.9),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, size: 20, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              'Renungan Sebelumnya',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkCharcoal,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Devotional>>(
          future: _devotionalService.getDevotionalHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: List.generate(
                  3,
                  (index) => const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: AppSkeleton(height: 72, borderRadius: AppTheme.cardRadius),
                  ),
                ),
              );
            }

            final history = snapshot.data ?? [];
            if (history.isEmpty) {
              return const AppCard(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Belum ada arsip renungan sebelumnya',
                    style: TextStyle(color: AppTheme.neutralMedium, fontSize: 13),
                  ),
                ),
              );
            }

            return Column(
              children: history.map((dev) {
                final isSelected = _activeDevotional?.id == dev.id;
                final dateStr = DateFormat('d MMM yyyy', 'id_ID').format(dev.date);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    color: isSelected ? AppTheme.primaryLight : Colors.white,
                    borderColor: isSelected ? AppTheme.primary : AppTheme.neutralBorder,
                    onTap: () {
                      setState(() {
                        _activeDevotional = dev;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: isSelected ? Colors.white : AppTheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        dev.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? AppTheme.primaryDark : AppTheme.darkCharcoal,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        color: isSelected ? AppTheme.primary : AppTheme.neutralMedium,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dev.verseReference,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.primary : AppTheme.goldDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: isSelected ? AppTheme.primary : AppTheme.neutralMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: const [
          AppSkeleton(height: 180, borderRadius: AppTheme.cardRadius),
          SizedBox(height: 16),
          AppSkeleton(height: 110, borderRadius: AppTheme.cardRadius),
          SizedBox(height: 16),
          AppSkeleton(height: 220, borderRadius: AppTheme.cardRadius),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: AppSkeleton(height: 48, borderRadius: AppTheme.cardRadius)),
              SizedBox(width: 12),
              Expanded(child: AppSkeleton(height: 48, borderRadius: AppTheme.cardRadius)),
            ],
          ),
        ],
      ),
    );
  }
}

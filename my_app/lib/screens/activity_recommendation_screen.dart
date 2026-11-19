import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/recommendation_provider.dart';
import '../services/recommendation_engine.dart';
import '../utils/app_theme.dart';
import '../utils/permissions.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_error_state.dart';

/// Admin decision-support screen (thesis RQ4/OBJ4): rule-based, explainable
/// recommendations computed from attendance, schedules, events and feedback.
class ActivityRecommendationScreen extends StatefulWidget {
  const ActivityRecommendationScreen({super.key});

  @override
  State<ActivityRecommendationScreen> createState() => _ActivityRecommendationScreenState();
}

class _ActivityRecommendationScreenState extends State<ActivityRecommendationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthProvider>().canAccess(AppModule.rekomendasi)) {
        context.read<RecommendationProvider>().generate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthProvider>().canAccess(AppModule.rekomendasi)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rekomendasi Kegiatan')),
        body: const AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Akses ditolak',
          description: 'Rekomendasi kegiatan hanya untuk admin dengan izin modul Rekomendasi.',
        ),
      );
    }

    final provider = context.watch<RecommendationProvider>();
    final result = provider.result;

    return Scaffold(
      backgroundColor: AppTheme.warmIvory,
      appBar: AppBar(
        title: Text(
          'Rekomendasi Kegiatan',
          style: TextStyle(color: AppTheme.darkCharcoal, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.darkCharcoal,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Hitung ulang',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: provider.isLoading ? null : () => provider.generate(),
          ),
        ],
      ),
      body: provider.isLoading && result == null
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && result == null
              ? AppErrorState(message: provider.error, onRetry: () => provider.generate())
              : result == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: () => provider.generate(),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        children: [
                          _SummaryCard(
                            summary: result.summary,
                            generatedAt: provider.generatedAt,
                          ),
                          const SizedBox(height: 16),
                          if (result.recommendations.isEmpty)
                            const AppEmptyState(
                              icon: Icons.check_circle_outline_rounded,
                              title: 'Tidak ada rekomendasi khusus',
                              description: 'Tidak ada data yang memenuhi kriteria rekomendasi '
                                  'saat ini. Kehadiran, kegiatan, dan feedback dalam batas wajar.',
                            )
                          else
                            ...result.recommendations.map((r) => _RecommendationCard(rec: r)),
                          const SizedBox(height: 8),
                          const _MethodNote(),
                        ],
                      ),
                    ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final RecommendationSummary summary;
  final DateTime? generatedAt;

  const _SummaryCard({required this.summary, required this.generatedAt});

  @override
  Widget build(BuildContext context) {
    final capacity = summary.buildingCapacity;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dasar Data Analisis',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.darkCharcoal),
          ),
          const SizedBox(height: 10),
          _row(Icons.church_outlined, 'Ibadah dengan data presensi', '${summary.serviceOccurrences}'),
          _row(Icons.how_to_reg_outlined, 'Catatan kehadiran terkonfirmasi', '${summary.attendanceRecords}'),
          _row(Icons.event_outlined, 'Kegiatan mendatang', '${summary.eventsConsidered}'),
          _row(Icons.rate_review_outlined,
              'Feedback (${RecommendationEngine.feedbackWindowDays} hari)', '${summary.feedbackConsidered}'),
          _row(Icons.meeting_room_outlined, 'Kapasitas gedung',
              capacity == null ? 'Belum dikonfigurasi' : '$capacity kursi'),
          if (generatedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Dihitung: ${DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(generatedAt!)}',
              style: TextStyle(fontSize: 11.5, color: AppTheme.neutralMedium),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.neutralMedium),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final ActivityRecommendation rec;

  const _RecommendationCard({required this.rec});

  ({Color color, IconData icon, String label}) get _style {
    switch (rec.severity) {
      case RecommendationSeverity.warning:
        return (color: AppTheme.errorColor, icon: Icons.priority_high_rounded, label: 'Prioritas');
      case RecommendationSeverity.attention:
        return (color: AppTheme.goldDark, icon: Icons.lightbulb_outline_rounded, label: 'Perlu Perhatian');
      case RecommendationSeverity.positive:
        return (color: AppTheme.emerald, icon: Icons.trending_up_rounded, label: 'Positif');
      case RecommendationSeverity.info:
        return (color: AppTheme.neutralMedium, icon: Icons.info_outline_rounded, label: 'Info');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderColor: s.color.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(s.icon, color: s.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: s.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rec.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkCharcoal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(rec.reason, style: const TextStyle(fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.warmIvory,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.neutralBorder),
            ),
            child: Text(
              'Dasar: ${rec.dataBasis}',
              style: TextStyle(fontSize: 12, color: AppTheme.neutralMedium),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodNote extends StatelessWidget {
  const _MethodNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Metode: rekomendasi berbasis aturan (rule-based) yang dapat dijelaskan. Keterisian '
      'dihitung dari rata-rata ${RecommendationEngine.utilizationWindow} ibadah terakhir '
      'terhadap kapasitas gedung (≥90% penuh, ≤40% rendah). Tren membandingkan '
      '${RecommendationEngine.trendWindow} ibadah terakhir dengan ${RecommendationEngine.trendWindow} '
      'sebelumnya (±20%). Feedback dinilai rendah bila rata-rata < 3,0 dan sangat baik bila ≥ 4,5 '
      '(minimal ${RecommendationEngine.minDataPoints} data). Rekomendasi adalah bahan pertimbangan '
      'pengurus, bukan keputusan otomatis.',
      style: TextStyle(fontSize: 11.5, color: AppTheme.neutralMedium, height: 1.4),
    );
  }
}

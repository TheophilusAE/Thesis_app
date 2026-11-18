import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/public_service.dart';
import '../services/supabase_service.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_error_state.dart';

typedef PublicScheduleLoader = Future<List<PublicServiceSlot>> Function(DateTime from, DateTime to);

/// Default loader: the public RPC (works for guests and members alike).
Future<List<PublicServiceSlot>> loadPublicSchedule(DateTime from, DateTime to) async {
  final rows = await SupabaseService().getPublicServiceSchedule(from, to);
  return rows.map(PublicServiceSlot.fromJson).toList();
}

/// Worship schedule for members (same public data the guest home shows).
class PublicScheduleScreen extends StatefulWidget {
  final PublicScheduleLoader? loader;
  const PublicScheduleScreen({super.key, this.loader});

  @override
  State<PublicScheduleScreen> createState() => _PublicScheduleScreenState();
}

class _PublicScheduleScreenState extends State<PublicScheduleScreen> {
  late Future<List<PublicServiceSlot>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<PublicServiceSlot>> _load() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    return (widget.loader ?? loadPublicSchedule)(from, from.add(const Duration(days: 30)));
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future.catchError((_) => <PublicServiceSlot>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Ibadah')),
      body: PublicScheduleView(schedule: _future, onRefresh: _refresh, showHeader: false),
    );
  }
}

/// Scrollable list of the next services grouped by day, with place and a
/// YouTube Live button when a link is set.
class PublicScheduleView extends StatelessWidget {
  final Future<List<PublicServiceSlot>> schedule;
  final Future<void> Function() onRefresh;
  final bool showHeader;

  const PublicScheduleView({
    super.key,
    required this.schedule,
    required this.onRefresh,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: FutureBuilder<List<PublicServiceSlot>>(
        future: schedule,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ListView(children: [
              const SizedBox(height: 80),
              AppErrorState(error: snap.error, onRetry: onRefresh),
            ]);
          }
          final groups = PublicServiceSlot.groupByDate(snap.data ?? const []);
          if (groups.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 80),
              AppEmptyState(
                icon: Icons.event_busy_rounded,
                title: 'Belum ada jadwal',
                description: 'Jadwal ibadah 30 hari ke depan belum diterbitkan.',
              ),
            ]);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              if (showHeader) ...[
                Text('Jadwal Ibadah',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('30 hari ke depan', style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
              ],
              for (final g in groups) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 6),
                  child: Text(
                    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(g.key),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                for (final s in g.value) ServiceSlotTile(slot: s, showDate: false),
              ],
            ],
          );
        },
      ),
    );
  }
}

class ServiceSlotTile extends StatelessWidget {
  final PublicServiceSlot slot;
  final bool showDate;
  const ServiceSlotTile({super.key, required this.slot, this.showDate = true});

  Future<void> _openLive(BuildContext context) async {
    final uri = Uri.tryParse(slot.youtubeUrl ?? '');
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan siaran tidak dapat dibuka.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final when = showDate
        ? '${DateFormat('EEE, d MMM', 'id_ID').format(slot.date)} • ${slot.timeLabel}'
        : slot.timeLabel;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          child: Icon(Icons.church_rounded, color: scheme.primary),
        ),
        title: Text(slot.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(slot.lokasi.isEmpty ? when : '$when\n${slot.lokasi}'),
        isThreeLine: slot.lokasi.isNotEmpty,
        trailing: slot.hasLive
            ? IconButton(
                tooltip: 'Tonton YouTube Live',
                icon: const Icon(Icons.live_tv_rounded, color: Colors.red),
                onPressed: () => _openLive(context),
              )
            : null,
      ),
    );
  }
}

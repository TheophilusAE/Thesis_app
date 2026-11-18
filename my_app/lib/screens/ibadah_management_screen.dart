import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/ibadah.dart';
import '../providers/auth_provider.dart';
import '../providers/ibadah_provider.dart';
import '../utils/permissions.dart';
import '../utils/qr_payload.dart';
import '../utils/recurrence.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_error_state.dart';
import 'add_edit_ibadah_series_screen.dart';
import 'checkin_qr_display_screen.dart';
import 'pelayanan_assignment_screen.dart';

/// Jadwal Ibadah (worship schedule): upcoming worship dates generated from
/// recurring series. Admins with `jadwal_ibadah:create` add schedules;
/// pelayan/kehadiran staff display the check-in QR; duties and rehearsals
/// are assigned per date; only Super Admin edits or cancels.
class IbadahManagementScreen extends StatefulWidget {
  const IbadahManagementScreen({super.key});

  @override
  State<IbadahManagementScreen> createState() => _IbadahManagementScreenState();
}

class _IbadahManagementScreenState extends State<IbadahManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<IbadahProvider>();
    final canCreate = context.read<AuthProvider>().can(AppModule.jadwalIbadah, PermissionAction.create);
    await provider.load();
    // Keep recurring schedules filled 90 days ahead (never changes existing dates).
    if (canCreate) await provider.ensureHorizon();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) await context.read<IbadahProvider>().load();
  }

  Future<void> _toggleCancelled(IbadahOccurrence o) async {
    final cancel = !o.isCancelled;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(cancel ? 'Batalkan ibadah tanggal ini?' : 'Aktifkan kembali?'),
        content: Text(cancel
            ? '${o.nama} pada ${DateFormat('EEEE, d MMM yyyy', 'id_ID').format(o.tanggal)} akan ditandai dibatalkan. '
                'Data tugas dan kehadiran tidak dihapus.'
            : 'Tanggal ini akan dijadwalkan kembali.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Kembali')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(cancel ? 'Batalkan' : 'Aktifkan')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final error = await context.read<IbadahProvider>().setOccurrenceCancelled(o.id, cancel);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? (cancel ? 'Ibadah dibatalkan.' : 'Ibadah diaktifkan kembali.'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<IbadahProvider>();
    final canView = auth.canAccess(AppModule.jadwalIbadah) ||
        auth.canAccess(AppModule.jadwalPelayanan) ||
        auth.isPelayan;
    final canCreate = auth.can(AppModule.jadwalIbadah, PermissionAction.create);
    final canAssign = auth.can(AppModule.jadwalPelayanan, PermissionAction.create);
    // Same rule as issue_checkin_token(): pelayan or kehadiran:create.
    final canShowQr = auth.isPelayan || auth.can(AppModule.kehadiran, PermissionAction.create);
    final isSuper = auth.canModifyExisting;

    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Jadwal Ibadah')),
        body: const AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Akses ditolak',
          description: 'Halaman ini untuk pelayan dan admin jadwal ibadah.',
        ),
      );
    }

    final groups = <DateTime, List<IbadahOccurrence>>{};
    for (final o in provider.occurrences) {
      groups.putIfAbsent(o.tanggal, () => []).add(o);
    }
    final days = groups.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Ibadah')),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _open(const AddEditIbadahSeriesScreen()),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Jadwal'),
            )
          : null,
      // One ListView for every state (loading / error / empty / data): the
      // scrollable under RefreshIndicator is never swapped for another widget
      // while the first load finishes during the page transition.
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                        children: [
                          if (provider.isLoading && provider.occurrences.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 80),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (provider.error != null && provider.occurrences.isEmpty) ...[
                            const SizedBox(height: 48),
                            AppErrorState(title: 'Jadwal belum dapat dimuat', message: provider.error, onRetry: _load),
                          ] else if (days.isEmpty) ...[
                            const SizedBox(height: 48),
                            const AppEmptyState(
                              icon: Icons.event_busy_rounded,
                              title: 'Belum ada jadwal ibadah',
                              description: 'Jadwal ibadah 60 hari ke depan akan tampil di sini.',
                            ),
                          ],
                          for (final d in days) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                              child: Text(
                                DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(d),
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            for (final o in groups[d]!)
                              _OccurrenceCard(
                                occurrence: o,
                                onQr: canShowQr && !o.isCancelled
                                    ? () => _open(CheckinQrDisplayScreen(
                                          targetType: CheckinTarget.occurrence,
                                          targetId: o.id,
                                          title: o.nama,
                                          subtitle:
                                              '${DateFormat('EEEE, d MMM yyyy', 'id_ID').format(o.tanggal)} • ${o.timeLabel}',
                                        ))
                                    : null,
                                onAssign: canAssign && !o.isCancelled
                                    ? () => _open(PelayananAssignmentScreen(occurrence: o))
                                    : null,
                                onEditSeries: isSuper
                                    ? () {
                                        final s = provider.seriesById(o.seriesId);
                                        if (s != null) _open(AddEditIbadahSeriesScreen(series: s));
                                      }
                                    : null,
                                onToggleCancelled: isSuper ? () => _toggleCancelled(o) : null,
                              ),
                          ],
                        ],
                      ),
      ),
    );
  }
}

class _OccurrenceCard extends StatelessWidget {
  final IbadahOccurrence occurrence;
  final VoidCallback? onQr;
  final VoidCallback? onAssign;
  final VoidCallback? onEditSeries;
  final VoidCallback? onToggleCancelled;

  const _OccurrenceCard({
    required this.occurrence,
    this.onQr,
    this.onAssign,
    this.onEditSeries,
    this.onToggleCancelled,
  });

  @override
  Widget build(BuildContext context) {
    final o = occurrence;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.nama,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          decoration: o.isCancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('${o.jenis} • ${o.timeLabel}', style: theme.textTheme.bodySmall),
                      if (o.lokasi.isNotEmpty)
                        Text(o.lokasi, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (onEditSeries != null || onToggleCancelled != null)
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') onEditSeries?.call();
                      if (v == 'cancel') onToggleCancelled?.call();
                    },
                    itemBuilder: (_) => [
                      if (onEditSeries != null)
                        const PopupMenuItem(value: 'edit', child: Text('Ubah jadwal (semua tanggal mendatang)')),
                      if (onToggleCancelled != null)
                        PopupMenuItem(
                          value: 'cancel',
                          child: Text(o.isCancelled ? 'Aktifkan kembali tanggal ini' : 'Batalkan tanggal ini'),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (o.isCancelled)
                  Chip(
                    label: const Text('Dibatalkan'),
                    backgroundColor: scheme.errorContainer,
                    labelStyle: TextStyle(color: scheme.onErrorContainer),
                    visualDensity: VisualDensity.compact,
                  ),
                if (o.pola != polaNone)
                  Chip(label: Text(recurrencePatternLabel(o.pola)), visualDensity: VisualDensity.compact),
                if (o.hasLive)
                  const Chip(
                    avatar: Icon(Icons.live_tv_rounded, size: 16, color: Colors.red),
                    label: Text('YouTube Live'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (onQr != null || onAssign != null) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  if (onQr != null)
                    TextButton.icon(
                      onPressed: onQr,
                      icon: const Icon(Icons.qr_code_2_rounded),
                      label: const Text('QR Presensi'),
                    ),
                  if (onAssign != null)
                    TextButton.icon(
                      onPressed: onAssign,
                      icon: const Icon(Icons.assignment_ind_outlined),
                      label: const Text('Tugaskan Pelayan'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

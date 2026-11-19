import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/broadcast.dart';
import '../models/notification.dart';
import '../providers/auth_provider.dart';
import '../providers/broadcast_provider.dart';
import '../utils/permissions.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/permission_guard.dart';

/// Pengumuman & Ucapan: admins with notifikasi:create send announcements
/// (to inboxes, shown on the home screen) and today's birthday greetings
/// (manual). Super Admin edits/archives announcements and can clean up old
/// notifications by hand — nothing is deleted automatically.
class BroadcastManagementScreen extends StatelessWidget {
  const BroadcastManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PermissionGuard(
      module: AppModule.notifikasi,
      title: 'Pengumuman & Ucapan',
      child: _BroadcastManagementBody(),
    );
  }
}

class _BroadcastManagementBody extends StatefulWidget {
  const _BroadcastManagementBody();

  @override
  State<_BroadcastManagementBody> createState() => _BroadcastManagementBodyState();
}

class _BroadcastManagementBodyState extends State<_BroadcastManagementBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final p = context.read<BroadcastProvider>();
    await p.load(activeOnly: false);
    if (mounted && context.read<AuthProvider>().can(AppModule.notifikasi, PermissionAction.create)) {
      await p.loadBirthdays();
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _create() async {
    final result = await showModalBottomSheet<_BroadcastDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _BroadcastForm(),
    );
    if (result == null || !mounted) return;
    final (error, recipients) = await context.read<BroadcastProvider>().create(
          title: result.title,
          message: result.message,
          category: result.category,
          audience: result.audience,
          route: result.route,
        );
    _snack(error ?? 'Pengumuman dikirim ke $recipients anggota.');
  }

  Future<void> _edit(Broadcast b) async {
    final result = await showModalBottomSheet<_BroadcastDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BroadcastForm(initial: b),
    );
    if (result == null || !mounted) return;
    final error = await context.read<BroadcastProvider>().update(
          b.id,
          title: result.title,
          message: result.message,
          category: result.category,
        );
    _snack(error ?? 'Pengumuman diperbarui, termasuk di inbox penerima.');
  }

  Future<void> _toggleActive(Broadcast b) async {
    final error = await context.read<BroadcastProvider>().update(b.id, isActive: !b.isActive);
    _snack(error ?? (b.isActive ? 'Pengumuman diarsipkan (tidak tampil di beranda).' : 'Pengumuman ditampilkan lagi.'));
  }

  Future<void> _sendBirthdays() async {
    final (error, names) = await context.read<BroadcastProvider>().sendBirthdayGreetings();
    _snack(error ?? (names.isEmpty ? 'Semua yang berulang tahun hari ini sudah menerima ucapan.' : 'Ucapan dikirim ke ${names.join(', ')}.'));
  }

  Future<void> _purge() async {
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Bersihkan notifikasi lama'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('Menghapus notifikasi SEMUA pengguna yang lebih lama dari batas yang dipilih. '
                'Tidak dapat dibatalkan.'),
          ),
          for (final d in const [30, 90, 180, 365])
            SimpleDialogOption(onPressed: () => Navigator.pop(ctx, d), child: Text('Lebih dari $d hari')),
        ],
      ),
    );
    if (days == null || !mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yakin?'),
        content: Text('Notifikasi lebih dari $days hari akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final (error, count) = await context.read<BroadcastProvider>().purgeOlderThan(days);
    _snack(error ?? '$count notifikasi lama dihapus.');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = context.watch<BroadcastProvider>();
    final canCreate = auth.can(AppModule.notifikasi, PermissionAction.create);
    final isSuper = auth.canModifyExisting;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumuman & Ucapan'),
        actions: [
          if (isSuper)
            IconButton(
              tooltip: 'Bersihkan notifikasi lama',
              icon: const Icon(Icons.cleaning_services_outlined),
              onPressed: _purge,
            ),
        ],
      ),
      floatingActionButton: canCreate && !p.featureMissing
          ? FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.campaign_rounded),
              label: const Text('Buat Pengumuman'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            if (p.featureMissing)
              const AppEmptyState(
                icon: Icons.build_circle_outlined,
                title: 'Fitur belum aktif',
                description: 'Jalankan migration_notifications_v2.sql di Supabase.',
              )
            else ...[
              if (canCreate) _BirthdayCard(people: p.birthdays, onSend: _sendBirthdays),
              const SizedBox(height: 12),
              Text('Pengumuman', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (p.isLoading && p.items.isEmpty)
                const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
              else if (p.error != null)
                Text(p.error!, style: TextStyle(color: theme.colorScheme.error))
              else if (p.items.isEmpty)
                const AppEmptyState(
                  icon: Icons.campaign_outlined,
                  title: 'Belum ada pengumuman',
                  description: 'Pengumuman yang dibuat tampil di beranda dan inbox anggota.',
                )
              else
                for (final b in p.items)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(NotificationCategory.icon(b.category),
                          color: b.isActive ? theme.colorScheme.primary : theme.disabledColor),
                      title: Text(b.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        '${b.message}\n${NotificationCategory.label(b.category)} • ${BroadcastAudience.label(b.audience)} • '
                        '${DateFormat('d MMM yyyy', 'id_ID').format(b.createdAt.toLocal())}'
                        '${b.isActive ? '' : ' • Diarsipkan'}${b.wasEdited ? ' • Diedit' : ''}',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: isSuper
                          ? PopupMenuButton<String>(
                              onSelected: (v) => v == 'edit' ? _edit(b) : _toggleActive(b),
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('Ubah')),
                                PopupMenuItem(value: 'toggle', child: Text(b.isActive ? 'Arsipkan' : 'Tampilkan lagi')),
                              ],
                            )
                          : null,
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BirthdayCard extends StatelessWidget {
  final List<BirthdayPerson> people;
  final VoidCallback onSend;
  const _BirthdayCard({required this.people, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = people.where((p) => !p.alreadyGreeted).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cake_rounded),
                const SizedBox(width: 8),
                Text('Ulang tahun hari ini', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            if (people.isEmpty)
              Text('Tidak ada anggota yang berulang tahun hari ini (berdasarkan tanggal lahir di profil).',
                  style: theme.textTheme.bodySmall)
            else
              for (final p in people)
                Text('• ${p.nama}${p.alreadyGreeted ? ' (sudah diberi ucapan)' : ''}'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: pending > 0 ? onSend : null,
                icon: const Icon(Icons.send_rounded),
                label: Text(pending > 0 ? 'Kirim ucapan hari ini ($pending)' : 'Kirim ucapan hari ini'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BroadcastDraft {
  final String title;
  final String message;
  final String category;
  final String audience;
  final String? route;
  const _BroadcastDraft(this.title, this.message, this.category, this.audience, this.route);
}

/// Create (all fields) or edit (title, message, category) an announcement.
class _BroadcastForm extends StatefulWidget {
  final Broadcast? initial;
  const _BroadcastForm({this.initial});

  @override
  State<_BroadcastForm> createState() => _BroadcastFormState();
}

class _BroadcastFormState extends State<_BroadcastForm> {
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _message = TextEditingController(text: widget.initial?.message ?? '');
  late String _category = widget.initial?.category ?? NotificationCategory.khusus;
  late String _audience = widget.initial?.audience ?? BroadcastAudience.semua;
  String? _route;
  String? _error;

  static const _routes = <String?, String>{
    null: 'Tidak ada (tampilkan isi pengumuman)',
    NotificationRoute.event: 'Event Gereja',
    NotificationRoute.jadwalIbadah: 'Jadwal Ibadah',
    NotificationRoute.renungan: 'Renungan Harian',
    NotificationRoute.quest: 'Quest Baca',
  };

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  void _submit() {
    final err = BroadcastProvider.validate(title: _title.text, message: _message.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pop(context, _BroadcastDraft(_title.text, _message.text, _category, _audience, _route));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(editing ? 'Ubah Pengumuman' : 'Buat Pengumuman', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            TextField(
              controller: _message,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Isi pengumuman'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [
                for (final c in NotificationCategory.all)
                  DropdownMenuItem(value: c, child: Text(NotificationCategory.label(c))),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            if (!editing) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _audience,
                decoration: const InputDecoration(labelText: 'Dikirim ke'),
                items: [
                  for (final a in BroadcastAudience.all)
                    DropdownMenuItem(value: a, child: Text(BroadcastAudience.label(a))),
                ],
                onChanged: (v) => setState(() => _audience = v ?? _audience),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _route,
                decoration: const InputDecoration(labelText: 'Saat diketuk, buka'),
                items: [
                  for (final e in _routes.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _route = v),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _submit, child: Text(editing ? 'Simpan' : 'Kirim')),
          ],
        ),
      ),
    );
  }
}

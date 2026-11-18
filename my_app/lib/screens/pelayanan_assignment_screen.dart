import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/ibadah.dart';
import '../models/pelayan.dart';
import '../providers/ibadah_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/pelayan_provider.dart';

/// One input for a worship date: choose the pelayan on duty and, optionally,
/// a rehearsal for the same people. Date, time, type and place come from the
/// worship date itself (they are not typed again and stay in sync when the
/// worship schedule changes).
class PelayananAssignmentScreen extends StatefulWidget {
  final IbadahOccurrence occurrence;
  const PelayananAssignmentScreen({super.key, required this.occurrence});

  @override
  State<PelayananAssignmentScreen> createState() => _PelayananAssignmentScreenState();
}

class _PelayananAssignmentScreenState extends State<PelayananAssignmentScreen> {
  final Set<String> _selected = {};
  final _notes = TextEditingController();
  bool _withRehearsal = false;
  late DateTime _rehearsalDate;
  TimeOfDay _rehearsalStart = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _rehearsalEnd = const TimeOfDay(hour: 20, minute: 0);
  late final TextEditingController _rehearsalLokasi;
  final _rehearsalNama = TextEditingController();
  bool _saving = false;

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final day = widget.occurrence.tanggal;
    final dayBefore = day.subtract(const Duration(days: 1));
    final today = DateTime.now();
    _rehearsalDate = dayBefore.isBefore(DateTime(today.year, today.month, today.day)) ? day : dayBefore;
    _rehearsalLokasi = TextEditingController(text: widget.occurrence.lokasi);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PelayaniProvider>().loadAllPelayan();
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    _rehearsalLokasi.dispose();
    _rehearsalNama.dispose();
    super.dispose();
  }

  Future<void> _save(List<Pelayan> active) async {
    final chosen = active.where((p) => _selected.contains(p.id)).toList();
    if (chosen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu pelayan.')),
      );
      return;
    }
    if (_withRehearsal &&
        (_rehearsalEnd.hour * 60 + _rehearsalEnd.minute) <= (_rehearsalStart.hour * 60 + _rehearsalStart.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jam selesai latihan harus setelah jam mulai.')),
      );
      return;
    }
    setState(() => _saving = true);
    final o = widget.occurrence;
    final notifications = context.read<NotificationProvider>();
    final error = await context.read<IbadahProvider>().assignPelayanan(
          occurrence: o,
          pelayan: chosen,
          notes: _notes.text,
          rehearsal: _withRehearsal
              ? RehearsalInput(
                  nama: _rehearsalNama.text,
                  date: DateTime(_rehearsalDate.year, _rehearsalDate.month, _rehearsalDate.day, 12),
                  startTime: _fmt(_rehearsalStart),
                  endTime: _fmt(_rehearsalEnd),
                  lokasi: _rehearsalLokasi.text,
                )
              : null,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final dateLabel = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(o.tanggal);
    final sent = await notifications.notifyUsers(
      userIds: chosen.where((p) => p.hasUserAccount).map((p) => p.userId),
      title: 'Jadwal Pelayanan Baru',
      message: 'Anda bertugas di ${o.nama} pada $dateLabel (${o.timeLabel})'
          '${_withRehearsal ? '. Latihan: ${DateFormat('EEE, d MMM', 'id_ID').format(_rehearsalDate)} ${_fmt(_rehearsalStart)}' : ''}.',
      type: 'schedule',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sent
            ? '${chosen.length} pelayan ditugaskan.'
            : '${chosen.length} pelayan ditugaskan, namun notifikasi gagal dikirim.'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.occurrence;
    final theme = Theme.of(context);
    final pelayan = context.watch<PelayaniProvider>();
    final active = pelayan.allPelayan.where((p) => p.isAktif).toList()
      ..sort((a, b) => a.nama.compareTo(b.nama));

    return Scaffold(
      appBar: AppBar(title: const Text('Tugaskan Pelayan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.church_rounded),
              title: Text(o.nama, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                '${DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(o.tanggal)} • ${o.timeLabel}'
                '${o.lokasi.isNotEmpty ? '\n${o.lokasi}' : ''}',
              ),
              isThreeLine: o.lokasi.isNotEmpty,
            ),
          ),
          const SizedBox(height: 12),
          Text('Pelayan yang bertugas', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          if (pelayan.isLoading)
            const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
          else if (active.isEmpty)
            const Text('Belum ada pelayan aktif.')
          else
            for (final p in active)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _selected.contains(p.id),
                title: Text(p.nama),
                subtitle: Text(p.posisi),
                onChanged: (v) => setState(() => v == true ? _selected.add(p.id) : _selected.remove(p.id)),
              ),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Catatan tugas (opsional)'),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _withRehearsal,
            onChanged: (v) => setState(() => _withRehearsal = v),
            title: const Text('Tambahkan jadwal latihan'),
            subtitle: const Text('Latihan dibuat untuk pelayan yang sama dan terhubung ke ibadah ini.'),
          ),
          if (_withRehearsal) ...[
            TextField(
              controller: _rehearsalNama,
              decoration: InputDecoration(labelText: 'Nama latihan', hintText: 'Latihan ${o.nama}'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: const Text('Tanggal latihan'),
              subtitle: Text(DateFormat('EEEE, d MMM yyyy', 'id_ID').format(_rehearsalDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _rehearsalDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: o.tanggal,
                );
                if (picked != null) setState(() => _rehearsalDate = picked);
              },
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Mulai'),
                    subtitle: Text(_fmt(_rehearsalStart)),
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: _rehearsalStart);
                      if (t != null) setState(() => _rehearsalStart = t);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Selesai'),
                    subtitle: Text(_fmt(_rehearsalEnd)),
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: _rehearsalEnd);
                      if (t != null) setState(() => _rehearsalEnd = t);
                    },
                  ),
                ),
              ],
            ),
            TextField(
              controller: _rehearsalLokasi,
              decoration: const InputDecoration(labelText: 'Lokasi latihan'),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving || pelayan.isLoading ? null : () => _save(active),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Simpan Penugasan'),
          ),
        ],
      ),
    );
  }
}

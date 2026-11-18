import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/ibadah.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/ibadah_provider.dart';
import '../utils/permissions.dart';
import '../utils/recurrence.dart';
import '../utils/youtube_url.dart';

/// Create a worship schedule (one date or a recurring series), or — Super
/// Admin — edit an existing series. Editing changes all future dates that
/// don't have their own override; past dates keep their recorded values.
class AddEditIbadahSeriesScreen extends StatefulWidget {
  final IbadahSeries? series;
  const AddEditIbadahSeriesScreen({super.key, this.series});

  @override
  State<AddEditIbadahSeriesScreen> createState() => _AddEditIbadahSeriesScreenState();
}

class _AddEditIbadahSeriesScreenState extends State<AddEditIbadahSeriesScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _lokasi;
  late final TextEditingController _deskripsi;
  late final TextEditingController _youtube;
  late String _jenis;
  String? _categoryId;
  late String _pola;
  late DateTime _startDate;
  DateTime? _endDate;
  late TimeOfDay _start;
  TimeOfDay? _end;
  bool _saving = false;

  bool get _editing => widget.series != null;

  static TimeOfDay? _parse(String s) {
    final m = RegExp(r'^(\d{1,2})[:.](\d{2})').firstMatch(s.trim());
    if (m == null) return null;
    return TimeOfDay(hour: int.parse(m.group(1)!), minute: int.parse(m.group(2)!));
  }

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final s = widget.series;
    _nama = TextEditingController(text: s?.nama ?? '');
    _lokasi = TextEditingController(text: s?.lokasi ?? '');
    _deskripsi = TextEditingController(text: s?.deskripsi ?? '');
    _youtube = TextEditingController(text: s?.youtubeUrl ?? '');
    _jenis = s?.jenis ?? ibadahJenisOptions.first;
    _categoryId = s?.categoryId;
    _pola = s?.pola ?? recurrenceWeekly;
    final today = DateTime.now();
    _startDate = s?.startDate ?? DateTime(today.year, today.month, today.day);
    _endDate = s?.endDate;
    _start = (s == null ? null : _parse(s.startTime)) ?? const TimeOfDay(hour: 8, minute: 0);
    _end = s == null ? const TimeOfDay(hour: 10, minute: 0) : _parse(s.endTime);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GroupProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _nama.dispose();
    _lokasi.dispose();
    _deskripsi.dispose();
    _youtube.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool end}) async {
    final first = end ? _startDate : DateTime.now().subtract(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: end ? (_endDate ?? _startDate) : _startDate,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() => end ? _endDate = picked : _startDate = picked);
  }

  Future<void> _pickTime({required bool end}) async {
    final picked = await showTimePicker(context: context, initialTime: end ? (_end ?? _start) : _start);
    if (picked == null) return;
    setState(() => end ? _end = picked : _start = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_end != null && (_end!.hour * 60 + _end!.minute) <= (_start.hour * 60 + _start.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jam selesai harus setelah jam mulai.')),
      );
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<IbadahProvider>();
    final youtube = _youtube.text.trim();
    String? error;
    if (_editing) {
      error = await provider.updateSeries(widget.series!.id, {
        'nama': _nama.text.trim(),
        'jenis': _jenis,
        'lokasi': _lokasi.text.trim(),
        'deskripsi': _deskripsi.text.trim(),
        'youtube_url': youtube,
        'start_time': _fmt(_start),
        'end_time': _end == null ? '' : _fmt(_end!),
        'end_date': _endDate == null ? '' : isoDate(_endDate!),
      });
    } else {
      error = await provider.createSeries(IbadahSeries(
        id: '',
        nama: _nama.text.trim(),
        jenis: _jenis,
        categoryId: _categoryId,
        deskripsi: _deskripsi.text.trim(),
        lokasi: _lokasi.text.trim(),
        youtubeUrl: youtube.isEmpty ? null : youtube,
        pola: _pola,
        startDate: _startDate,
        endDate: _pola == polaNone ? null : _endDate,
        startTime: _fmt(_start),
        endTime: _end == null ? '' : _fmt(_end!),
      ));
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_editing ? 'Jadwal ibadah diperbarui.' : 'Jadwal ibadah dibuat.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final categories = context
        .watch<GroupProvider>()
        .categories
        .where((c) => auth.can(AppModule.jadwalIbadah, PermissionAction.create, categoryId: c.id))
        .toList();
    final dateFmt = DateFormat('EEE, d MMM yyyy', 'id_ID');
    final previewCount = _editing
        ? 0
        : IbadahDates.forNewSeries(start: _startDate, pola: _pola, endDate: _endDate).length;

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Ubah Jadwal Ibadah' : 'Tambah Jadwal Ibadah')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(
                labelText: 'Nama ibadah',
                hintText: 'mis. Ibadah Raya Minggu Pagi',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: ibadahJenisOptions.contains(_jenis) ? _jenis : ibadahJenisOptions.first,
              decoration: const InputDecoration(labelText: 'Jenis ibadah'),
              items: [for (final j in ibadahJenisOptions) DropdownMenuItem(value: j, child: Text(j))],
              onChanged: (v) => setState(() => _jenis = v ?? _jenis),
            ),
            if (!_editing && categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                decoration: const InputDecoration(labelText: 'Kategori (opsional)'),
                items: [
                  if (auth.can(AppModule.jadwalIbadah, PermissionAction.create))
                    const DropdownMenuItem<String?>(value: null, child: Text('Tanpa kategori')),
                  for (final c in categories) DropdownMenuItem<String?>(value: c.id, child: Text(c.nama)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            ],
            const SizedBox(height: 16),
            if (!_editing) ...[
              Text('Pengulangan', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final p in [polaNone, ...recurrencePatterns])
                    ChoiceChip(
                      label: Text(p == polaNone ? 'Sekali' : recurrencePatternLabel(p)),
                      selected: _pola == p,
                      onSelected: (_) => setState(() => _pola = p),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_rounded),
                title: Text(_pola == polaNone ? 'Tanggal' : 'Mulai tanggal'),
                subtitle: Text(dateFmt.format(_startDate)),
                onTap: () => _pickDate(end: false),
              ),
            ] else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.repeat_rounded),
                title: Text(widget.series!.isRecurring
                    ? 'Pengulangan: ${recurrencePatternLabel(widget.series!.pola)}'
                    : 'Sekali'),
                subtitle: Text('Mulai ${dateFmt.format(widget.series!.startDate)} • '
                    'pola & tanggal mulai tidak dapat diubah (buat jadwal baru bila perlu)'),
              ),
            if (_pola != polaNone || (_editing && widget.series!.isRecurring))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_busy_rounded),
                title: const Text('Berakhir (opsional)'),
                subtitle: Text(_endDate == null ? 'Tanpa batas' : dateFmt.format(_endDate!)),
                trailing: _endDate == null
                    ? null
                    : IconButton(
                        tooltip: 'Hapus batas',
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() => _endDate = null),
                      ),
                onTap: () => _pickDate(end: true),
              ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Mulai'),
                    subtitle: Text(_fmt(_start)),
                    onTap: () => _pickTime(end: false),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Selesai'),
                    subtitle: Text(_end == null ? '-' : _fmt(_end!)),
                    onTap: () => _pickTime(end: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lokasi,
              decoration: const InputDecoration(labelText: 'Lokasi', hintText: 'mis. Gedung Gereja Utama'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _deskripsi,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _youtube,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Link YouTube Live (opsional)',
                hintText: 'https://youtube.com/live/...',
                prefixIcon: Icon(Icons.live_tv_rounded),
              ),
              validator: validateYoutubeUrl,
            ),
            if (!_editing) ...[
              const SizedBox(height: 16),
              Text(
                _pola == polaNone
                    ? 'Akan dibuat 1 tanggal ibadah.'
                    : 'Akan dibuat $previewCount tanggal untuk $defaultRecurrenceHorizonDays hari ke depan; '
                        'tanggal berikutnya ditambahkan otomatis. Semua tanggal memakai satu ID jadwal yang sama.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text(
                'Perubahan berlaku untuk tanggal hari ini dan seterusnya. Tanggal yang sudah lewat '
                'tetap memakai data lama, sehingga histori kehadiran tidak berubah.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_editing ? 'Simpan Perubahan' : 'Buat Jadwal Ibadah'),
            ),
          ],
        ),
      ),
    );
  }
}

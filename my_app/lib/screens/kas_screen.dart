import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/kas.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/kas_provider.dart';
import '../utils/permissions.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_error_state.dart';

final _rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final _tgl = DateFormat('d MMM yyyy', 'id_ID');

/// Kas Keuangan & Rekening Dompet Kas.
/// Admin: view & add (only accounts granted to them); Super Admin: full CRUD
/// and per-account access management. Enforced by RLS + RPCs.
class KasScreen extends StatefulWidget {
  const KasScreen({super.key});

  @override
  State<KasScreen> createState() => _KasScreenState();
}

class _KasScreenState extends State<KasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<KasProvider>().loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canKas = auth.canAccess(AppModule.kas);
    final canRekening = auth.canAccess(AppModule.rekening);
    if (!canKas && !canRekening) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kas Keuangan')),
        body: const AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Akses ditolak',
          description: 'Akun Anda belum diberi izin modul Kas Keuangan / Rekening. Hubungi Super Admin.',
        ),
      );
    }
    final tabs = <({String label, Widget view})>[
      if (canKas) (label: 'Transaksi', view: const _TransaksiTab()),
      if (canRekening) (label: 'Rekening', view: const _RekeningTab()),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kas Keuangan'),
          bottom: tabs.length > 1 ? TabBar(tabs: [for (final t in tabs) Tab(text: t.label)]) : null,
        ),
        body: tabs.length > 1 ? TabBarView(children: [for (final t in tabs) t.view]) : tabs.single.view,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaksi
// ─────────────────────────────────────────────────────────────────────────────

class _TransaksiTab extends StatelessWidget {
  const _TransaksiTab();

  @override
  Widget build(BuildContext context) {
    final kas = context.watch<KasProvider>();
    final auth = context.watch<AuthProvider>();
    final canCreate = auth.can(AppModule.kas, PermissionAction.create);
    final canModify = auth.canModifyExisting;
    final r = kas.ringkasan;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: canCreate && kas.akunAktif.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const _TransaksiForm(),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Catat Transaksi'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: kas.loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            const _FilterBar(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _SumTile(label: 'Masuk', value: r.masuk, color: Colors.green.shade700)),
                const SizedBox(width: 8),
                Expanded(child: _SumTile(label: 'Keluar', value: r.keluar, color: scheme.error)),
                const SizedBox(width: 8),
                Expanded(child: _SumTile(label: 'Selisih', value: r.selisih, color: scheme.primary)),
              ],
            ),
            const SizedBox(height: 12),
            if (kas.isLoading && kas.transaksi.isEmpty)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (kas.error != null && kas.transaksi.isEmpty)
              AppErrorState(title: 'Data kas belum dapat dimuat', message: kas.error, onRetry: kas.loadAll)
            else if (kas.transaksi.isEmpty)
              AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada transaksi',
                description: kas.filter.isEmpty
                    ? (kas.akunAktif.isEmpty
                        ? 'Belum ada rekening yang dapat Anda akses.'
                        : 'Transaksi yang dicatat akan tampil di sini.')
                    : 'Tidak ada transaksi yang cocok dengan filter.',
              )
            else
              for (final t in kas.transaksi)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (t.isMasuk ? Colors.green : scheme.error).withValues(alpha: 0.12),
                      child: Icon(
                        t.isMasuk ? Icons.south_west_rounded : Icons.north_east_rounded,
                        color: t.isMasuk ? Colors.green.shade700 : scheme.error,
                      ),
                    ),
                    title: Text(t.kategori, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text([
                      '${_tgl.format(t.tanggal)} • ${kas.namaAkun(t.kasAkunId)}',
                      if ((t.namaPembayarPenerima ?? '').isNotEmpty) t.namaPembayarPenerima!,
                      if ((t.keterangan ?? '').isNotEmpty) t.keterangan!,
                      t.kodeTransaksi,
                    ].join('\n')),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${t.isMasuk ? '+' : '−'}${_rupiah.format(t.nominal)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: t.isMasuk ? Colors.green.shade700 : scheme.error,
                          ),
                        ),
                      ],
                    ),
                    onLongPress: canModify ? () => _superAdminActions(context, t) : null,
                  ),
                ),
            if (canModify && kas.transaksi.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Tekan lama transaksi untuk mengubah atau menghapus (Super Admin).',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _superAdminActions(BuildContext context, KasTransaksi t) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Ubah transaksi'),
            onTap: () => Navigator.pop(ctx, 'edit'),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: Theme.of(ctx).colorScheme.error),
            title: const Text('Hapus transaksi'),
            onTap: () => Navigator.pop(ctx, 'delete'),
          ),
        ]),
      ),
    );
    if (!context.mounted || action == null) return;
    final kas = context.read<KasProvider>();
    if (action == 'edit') {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _TransaksiForm(existing: t),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: Text('${t.kodeTransaksi} • ${_rupiah.format(t.nominal)}\nTindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    final error = await kas.deleteTransaksi(t);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Transaksi dihapus.')));
  }
}

class _SumTile extends StatelessWidget {
  final String label;
  final num value;
  final Color color;
  const _SumTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(_rupiah.format(value),
                  style: TextStyle(fontWeight: FontWeight.w800, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatefulWidget {
  const _FilterBar();

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  final _kategori = TextEditingController();

  @override
  void dispose() {
    _kategori.dispose();
    super.dispose();
  }

  void _apply(KasFilter f) => context.read<KasProvider>().loadTransaksi(f);

  @override
  Widget build(BuildContext context) {
    final kas = context.watch<KasProvider>();
    final f = kas.filter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: f.akunId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Rekening', isDense: true),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Semua rekening')),
                  for (final a in kas.akun) DropdownMenuItem<int?>(value: a.id, child: Text(a.namaAkun)),
                ],
                onChanged: (v) => _apply(v == null ? f.copyWith(clearAkun: true) : f.copyWith(akunId: v)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Rentang tanggal',
              icon: const Icon(Icons.date_range_rounded),
              onPressed: () async {
                final now = DateTime.now();
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(now.year - 5),
                  lastDate: now,
                  initialDateRange: f.from != null && f.to != null
                      ? DateTimeRange(start: f.from!, end: f.to!)
                      : null,
                );
                if (range != null) _apply(f.copyWith(from: range.start, to: range.end));
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Semua'),
              selected: f.jenis == null,
              onSelected: (_) => _apply(f.copyWith(clearJenis: true)),
            ),
            ChoiceChip(
              label: const Text('Masuk'),
              selected: f.jenis == KasJenis.masuk,
              onSelected: (_) => _apply(f.copyWith(jenis: KasJenis.masuk)),
            ),
            ChoiceChip(
              label: const Text('Keluar'),
              selected: f.jenis == KasJenis.keluar,
              onSelected: (_) => _apply(f.copyWith(jenis: KasJenis.keluar)),
            ),
            if (f.from != null && f.to != null)
              InputChip(
                label: Text('${_tgl.format(f.from!)} – ${_tgl.format(f.to!)}'),
                onDeleted: () => _apply(f.copyWith(clearDates: true)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _kategori,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            isDense: true,
            labelText: 'Cari kategori',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: (f.kategori ?? '').isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _kategori.clear();
                      _apply(f.copyWith(kategori: ''));
                    },
                  ),
          ),
          onSubmitted: (v) => _apply(f.copyWith(kategori: v.trim())),
        ),
      ],
    );
  }
}

class _TransaksiForm extends StatefulWidget {
  final KasTransaksi? existing; // Super Admin edit
  const _TransaksiForm({this.existing});

  @override
  State<_TransaksiForm> createState() => _TransaksiFormState();
}

class _TransaksiFormState extends State<_TransaksiForm> {
  late int? _akunId;
  late String _jenis;
  late final TextEditingController _kategori;
  late final TextEditingController _nominal;
  late final TextEditingController _pihak;
  late final TextEditingController _keterangan;
  late DateTime _tanggal;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    final kas = context.read<KasProvider>();
    _akunId = t?.kasAkunId ?? (kas.akunAktif.isEmpty ? null : kas.akunAktif.first.id);
    _jenis = t?.jenis ?? KasJenis.masuk;
    _kategori = TextEditingController(text: t?.kategori ?? '');
    _nominal = TextEditingController(text: t == null ? '' : t.nominal.toStringAsFixed(0));
    _pihak = TextEditingController(text: t?.namaPembayarPenerima ?? '');
    _keterangan = TextEditingController(text: t?.keterangan ?? '');
    final now = DateTime.now();
    _tanggal = t?.tanggal ?? DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _kategori.dispose();
    _nominal.dispose();
    _pihak.dispose();
    _keterangan.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nominal = num.tryParse(_nominal.text.replaceAll('.', '').trim()) ?? 0;
    final kas = context.read<KasProvider>();
    setState(() => _saving = true);
    final String? error;
    if (widget.existing != null) {
      error = await kas.updateTransaksi(
        widget.existing!,
        kategori: _kategori.text,
        nominal: nominal,
        tanggal: _tanggal,
        namaPembayarPenerima: _pihak.text.trim().isEmpty ? null : _pihak.text.trim(),
        keterangan: _keterangan.text.trim().isEmpty ? null : _keterangan.text.trim(),
      );
    } else if (_akunId == null) {
      error = 'Pilih rekening.';
    } else {
      error = await kas.createTransaksi(
        kasAkunId: _akunId!,
        jenis: _jenis,
        kategori: _kategori.text,
        tanggal: _tanggal,
        nominal: nominal,
        namaPembayarPenerima: _pihak.text.trim().isEmpty ? null : _pihak.text.trim(),
        keterangan: _keterangan.text.trim().isEmpty ? null : _keterangan.text.trim(),
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.existing != null ? 'Transaksi diperbarui.' : 'Transaksi dicatat.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kas = context.watch<KasProvider>();
    final editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(editing ? 'Ubah Transaksi' : 'Catat Transaksi',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (!editing) ...[
              DropdownButtonFormField<int>(
                initialValue: _akunId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Rekening'),
                items: [for (final a in kas.akunAktif) DropdownMenuItem(value: a.id, child: Text(a.namaAkun))],
                onChanged: (v) => setState(() => _akunId = v),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: KasJenis.masuk, label: Text('Masuk'), icon: Icon(Icons.south_west_rounded)),
                  ButtonSegment(value: KasJenis.keluar, label: Text('Keluar'), icon: Icon(Icons.north_east_rounded)),
                ],
                selected: {_jenis},
                onSelectionChanged: (s) => setState(() => _jenis = s.first),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _kategori,
              decoration: const InputDecoration(labelText: 'Kategori', hintText: 'mis. Persembahan'),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final k in kasKategoriSaran)
                  ActionChip(
                    label: Text(k),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _kategori.text = k),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nominal,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: const Text('Tanggal'),
              subtitle: Text(_tgl.format(_tanggal)),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _tanggal,
                  firstDate: DateTime(now.year - 5),
                  lastDate: now,
                );
                if (picked != null) setState(() => _tanggal = picked);
              },
            ),
            TextField(
              controller: _pihak,
              decoration: InputDecoration(
                labelText: _jenis == KasJenis.masuk ? 'Nama pemberi (opsional)' : 'Nama penerima (opsional)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keterangan,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Keterangan (opsional)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rekening
// ─────────────────────────────────────────────────────────────────────────────

class _RekeningTab extends StatelessWidget {
  const _RekeningTab();

  @override
  Widget build(BuildContext context) {
    final kas = context.watch<KasProvider>();
    final auth = context.watch<AuthProvider>();
    final canCreate = auth.can(AppModule.rekening, PermissionAction.create);
    final isSuper = auth.canModifyExisting;
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const _RekeningForm(),
              ),
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('Tambah Rekening'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: kas.loadAkun,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet_rounded),
                title: const Text('Total saldo (rekening yang dapat Anda lihat)'),
                subtitle: Text(_rupiah.format(kas.totalSaldo),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 8),
            if (kas.akun.isEmpty)
              AppEmptyState(
                icon: Icons.account_balance_outlined,
                title: 'Belum ada rekening',
                description: kas.error ??
                    'Rekening yang dapat Anda akses akan tampil di sini. Akses rekening diatur oleh Super Admin.',
              )
            else
              for (final a in kas.akun)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.account_balance_rounded,
                        color: a.isAktif ? theme.colorScheme.primary : theme.disabledColor),
                    title: Text(a.namaAkun, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text([
                      if ((a.nomorRekening ?? '').isNotEmpty) a.nomorRekening!,
                      if ((a.atasNama ?? '').isNotEmpty) 'a.n. ${a.atasNama}',
                      'Saldo awal ${_rupiah.format(a.saldoAwal)} • masuk ${_rupiah.format(a.totalMasuk)} • keluar ${_rupiah.format(a.totalKeluar)}',
                      if (!a.isAktif) 'Nonaktif',
                    ].join('\n')),
                    isThreeLine: true,
                    trailing: Text(_rupiah.format(a.saldo), style: const TextStyle(fontWeight: FontWeight.w800)),
                    onTap: isSuper ? () => _superAdminActions(context, a) : null,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _superAdminActions(BuildContext context, KasAkun a) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('Atur akses admin'),
            onTap: () => Navigator.pop(ctx, 'access'),
          ),
          ListTile(
            leading: Icon(a.isAktif ? Icons.block_rounded : Icons.check_circle_outline_rounded),
            title: Text(a.isAktif ? 'Nonaktifkan rekening' : 'Aktifkan rekening'),
            onTap: () => Navigator.pop(ctx, 'toggle'),
          ),
        ]),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'toggle') {
      final error = await context.read<KasProvider>().setAkunAktif(a, !a.isAktif);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? (a.isAktif ? 'Rekening dinonaktifkan.' : 'Rekening diaktifkan.'))),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AccessSheet(akun: a),
    );
  }
}

class _RekeningForm extends StatefulWidget {
  const _RekeningForm();

  @override
  State<_RekeningForm> createState() => _RekeningFormState();
}

class _RekeningFormState extends State<_RekeningForm> {
  final _nama = TextEditingController();
  final _nomor = TextEditingController();
  final _atasNama = TextEditingController();
  final _saldo = TextEditingController(text: '0');
  final _ket = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_nama, _nomor, _atasNama, _saldo, _ket]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final error = await context.read<KasProvider>().createAkun(
          namaAkun: _nama.text,
          nomorRekening: _nomor.text.trim().isEmpty ? null : _nomor.text.trim(),
          atasNama: _atasNama.text.trim().isEmpty ? null : _atasNama.text.trim(),
          saldoAwal: num.tryParse(_saldo.text.trim()) ?? 0,
          keterangan: _ket.text.trim().isEmpty ? null : _ket.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rekening ditambahkan.')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tambah Rekening / Dompet Kas', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(controller: _nama, decoration: const InputDecoration(labelText: 'Nama rekening', hintText: 'mis. Kas Tunai, BCA Gereja')),
            const SizedBox(height: 12),
            TextField(controller: _nomor, decoration: const InputDecoration(labelText: 'Nomor rekening (opsional)')),
            const SizedBox(height: 12),
            TextField(controller: _atasNama, decoration: const InputDecoration(labelText: 'Atas nama (opsional)')),
            const SizedBox(height: 12),
            TextField(
              controller: _saldo,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Saldo awal (Rp)'),
            ),
            const SizedBox(height: 12),
            TextField(controller: _ket, decoration: const InputDecoration(labelText: 'Keterangan (opsional)')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Super Admin: who (which admins) may view / add transactions on an account.
class _AccessSheet extends StatefulWidget {
  final KasAkun akun;
  const _AccessSheet({required this.akun});

  @override
  State<_AccessSheet> createState() => _AccessSheetState();
}

class _AccessSheetState extends State<_AccessSheet> {
  late Future<(List<KasAkunAccess>, List<User>)> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<(List<KasAkunAccess>, List<User>)> _load() async {
    final access = await context.read<KasProvider>().loadAccess(widget.akun.id);
    if (!mounted) return (access, <User>[]);
    final users = await context.read<AuthProvider>().getAllUsers();
    final admins = users.where((u) => u.hasRole('admin') && !u.hasRole('super_admin')).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return (access, admins);
  }

  Future<void> _set(User u, {required bool read, required bool create}) async {
    final error = await context.read<KasProvider>().setAccess(
          akunId: widget.akun.id,
          userId: u.id,
          canRead: read,
          canCreate: create,
        );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
    setState(() => _data = _load());
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (context, scroll) => FutureBuilder<(List<KasAkunAccess>, List<User>)>(
        future: _data,
        builder: (context, snap) {
          if (!snap.hasData) {
            return snap.hasError
                ? Center(child: Text(KasProvider.messageFor(snap.error!)))
                : const Center(child: CircularProgressIndicator());
          }
          final (access, admins) = snap.data!;
          KasAkunAccess? of(User u) {
            for (final a in access) {
              if (a.userId == u.id) return a;
            }
            return null;
          }

          return ListView(
            controller: scroll,
            padding: const EdgeInsets.all(16),
            children: [
              Text('Akses "${widget.akun.namaAkun}"', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Admin juga perlu izin modul Kas/Rekening di "Kelola Admin & Izin". '
                'Ubah/hapus tetap khusus Super Admin.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (admins.isEmpty) const Text('Belum ada admin.'),
              for (final u in admins)
                Builder(builder: (context) {
                  final a = of(u);
                  final read = a?.canRead ?? false;
                  final create = a?.canCreate ?? false;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          FilterChip(
                            label: const Text('Lihat'),
                            selected: read,
                            onSelected: (v) => _set(u, read: v, create: v ? create : false),
                          ),
                          const SizedBox(width: 6),
                          FilterChip(
                            label: const Text('Tambah'),
                            selected: create,
                            onSelected: (v) => _set(u, read: v ? true : read, create: v),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

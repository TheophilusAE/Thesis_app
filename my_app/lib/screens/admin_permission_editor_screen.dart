import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/admin_permission.dart';
import '../models/user.dart';
import '../providers/admin_access_provider.dart';
import '../utils/permissions.dart';
import '../widgets/permission_guard.dart';

/// Super Admin edits one Admin's permissions: for each category scope
/// (or "Semua kategori"), which modules the Admin may add to (Tambah),
/// view (Lihat) and — where it exists — approve (Setujui). Editing and
/// deleting existing data is never grantable: it stays Super Admin only.
class AdminPermissionEditorScreen extends StatefulWidget {
  final User admin;
  const AdminPermissionEditorScreen({super.key, required this.admin});

  @override
  State<AdminPermissionEditorScreen> createState() => _AdminPermissionEditorScreenState();
}

/// Key for one (module, category) cell; category null = all categories.
typedef _CellKey = ({String module, String? categoryId});

class _AdminPermissionEditorScreenState extends State<AdminPermissionEditorScreen> {
  final Map<_CellKey, AdminPermission> _grants = {};
  String? _scope; // selected category id; null = all categories
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final existing = context.read<AdminAccessProvider>().permissionsFor(widget.admin.id);
    for (final g in existing) {
      _grants[(module: g.module, categoryId: g.categoryId)] = g;
    }
  }

  AdminPermission _cell(String module) =>
      _grants[(module: module, categoryId: _scope)] ??
      AdminPermission(userId: widget.admin.id, module: module, categoryId: _scope);

  void _toggle(String module, {bool? create, bool? read, bool? approve}) {
    final current = _cell(module);
    var next = current.copyWith(canCreate: create, canRead: read, canApprove: approve);
    // Adding or approving data without being able to see it makes no sense.
    if ((next.canCreate || next.canApprove) && !next.canRead) {
      next = next.copyWith(canRead: true);
    }
    setState(() {
      _grants[(module: module, categoryId: _scope)] = next;
      _dirty = true;
    });
  }

  void _setAllInScope({required bool enable}) {
    setState(() {
      for (final m in AppModule.all) {
        if (AppModule.financial.contains(m)) continue; // finance: explicit only
        _grants[(module: m, categoryId: _scope)] = AdminPermission(
          userId: widget.admin.id,
          module: m,
          categoryId: _scope,
          canCreate: enable,
          canRead: enable,
        );
      }
      _dirty = true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final provider = context.read<AdminAccessProvider>();
    final ok = await provider.savePermissions(widget.admin.id, _grants.values.toList());
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _dirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Izin ${widget.admin.name} disimpan. Berlaku saat admin membuka ulang aplikasi.'
            : (provider.error ?? 'Gagal menyimpan izin.')),
      ),
    );
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buang perubahan?'),
        content: const Text('Perubahan izin belum disimpan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Kembali')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Buang')),
        ],
      ),
    );
    return discard ?? false;
  }

  int _grantCount(String? categoryId) => _grants.entries
      .where((e) => e.key.categoryId == categoryId && !e.value.isEmpty)
      .length;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminAccessProvider>();
    final categories = provider.activeCategories;
    final theme = Theme.of(context);

    return PermissionGuard(
      superAdminOnly: true,
      title: 'Izin Admin',
      child: PopScope(
        canPop: !_dirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final navigator = Navigator.of(context);
          if (await _confirmDiscard()) {
            _dirty = false;
            navigator.pop();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('Izin: ${widget.admin.name}'),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Aksi cepat',
                onSelected: (v) => _setAllInScope(enable: v == 'all'),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'all', child: Text('Tambah + Lihat semua modul (non-keuangan)')),
                  PopupMenuItem(value: 'none', child: Text('Kosongkan izin di cakupan ini')),
                ],
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              onPressed: _saving || !_dirty ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: const Text('Simpan Izin'),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text('Cakupan kategori', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('Semua kategori (${_grantCount(null)})'),
                    selected: _scope == null,
                    onSelected: (_) => setState(() => _scope = null),
                  ),
                  for (final c in categories)
                    ChoiceChip(
                      label: Text('${c.nama} (${_grantCount(c.id)})'),
                      selected: _scope == c.id,
                      onSelected: (_) => setState(() => _scope = c.id),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _scope == null
                    ? 'Izin di cakupan ini berlaku untuk data semua kategori.'
                    : 'Izin di cakupan ini hanya berlaku untuk data kategori '
                        '${provider.categoryName(_scope)}.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Mengubah atau menghapus data yang sudah ada selalu khusus Super Admin.',
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              for (final module in AppModule.all) _moduleCard(context, module),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moduleCard(BuildContext context, String module) {
    final cell = _cell(module);
    final financial = AppModule.financial.contains(module);
    final approvable = AppModule.approvable.contains(module);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppModule.label(module),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (financial)
                  Tooltip(
                    message: 'Data keuangan — berikan hanya jika benar-benar diperlukan',
                    child: Icon(Icons.lock_rounded, size: 18, color: scheme.error),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                FilterChip(
                  label: const Text('Lihat'),
                  selected: cell.canRead,
                  onSelected: (v) => _toggle(module,
                      read: v,
                      // Removing read also removes what depends on it.
                      create: v ? null : false,
                      approve: v ? null : false),
                ),
                FilterChip(
                  label: const Text('Tambah'),
                  selected: cell.canCreate,
                  onSelected: (v) => _toggle(module, create: v),
                ),
                if (approvable)
                  FilterChip(
                    label: const Text('Setujui'),
                    selected: cell.canApprove,
                    onSelected: (v) => _toggle(module, approve: v),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

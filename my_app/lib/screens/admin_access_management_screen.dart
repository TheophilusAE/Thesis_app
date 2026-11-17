import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/admin_category.dart';
import '../models/user.dart';
import '../providers/admin_access_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_error_state.dart';
import '../widgets/permission_guard.dart';
import 'admin_permission_editor_screen.dart';

/// Super Admin: manage which accounts are Admin, what each Admin may do
/// (module × action × category) and the list of administrative categories.
class AdminAccessManagementScreen extends StatefulWidget {
  const AdminAccessManagementScreen({super.key});

  @override
  State<AdminAccessManagementScreen> createState() => _AdminAccessManagementScreenState();
}

class _AdminAccessManagementScreenState extends State<AdminAccessManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthProvider>().isSuperAdmin) {
        context.read<AdminAccessProvider>().load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      superAdminOnly: true,
      title: 'Kelola Admin & Izin',
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Kelola Admin & Izin'),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.admin_panel_settings_rounded), text: 'Admin'),
                Tab(icon: Icon(Icons.category_rounded), text: 'Kategori'),
              ],
            ),
          ),
          body: Consumer<AdminAccessProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.admins.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.error != null && provider.admins.isEmpty && provider.categories.isEmpty) {
                return AppErrorState(
                  message: provider.error!,
                  onRetry: provider.load,
                );
              }
              return const TabBarView(
                children: [_AdminListTab(), _CategoryTab()],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin list
// ─────────────────────────────────────────────────────────────────────────────

class _AdminListTab extends StatelessWidget {
  const _AdminListTab();

  Future<void> _addAdmin(BuildContext context) async {
    final provider = context.read<AdminAccessProvider>();
    final user = await showModalBottomSheet<User>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _UserPickerSheet(users: provider.promotableUsers),
    );
    if (user == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Jadikan Admin?'),
        content: Text(
          '${user.name} akan mendapat role Admin tanpa izin modul apa pun. '
          'Atur izinnya di langkah berikutnya.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Jadikan Admin')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await provider.promoteToAdmin(user);
    if (!context.mounted) return;
    if (!ok) {
      _snack(context, provider.error ?? 'Gagal menjadikan admin.');
      return;
    }
    final promoted = provider.admins.firstWhere((u) => u.id == user.id, orElse: () => user);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminPermissionEditorScreen(admin: promoted)),
    );
  }

  Future<void> _revoke(BuildContext context, User admin) async {
    final provider = context.read<AdminAccessProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cabut role Admin?'),
        content: Text(
          'Semua izin admin ${admin.name} akan dihapus. Akunnya tetap aktif sebagai anggota.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cabut'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await provider.revokeAdmin(admin);
    if (!context.mounted) return;
    _snack(context, ok ? 'Role admin ${admin.name} dicabut.' : (provider.error ?? 'Gagal mencabut role.'));
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _summary(AdminAccessProvider provider, User admin) {
    if (admin.hasRole('super_admin')) return 'Akses penuh ke semua modul';
    final grants = provider.permissionsFor(admin.id);
    if (grants.isEmpty) return 'Belum ada izin — admin ini belum bisa mengakses modul apa pun';
    final modules = grants.map((g) => g.module).toSet().length;
    final categories = grants.map((g) => provider.categoryName(g.categoryId)).toSet().join(', ');
    return '$modules modul • $categories';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminAccessProvider>();
    final me = context.watch<AuthProvider>().currentUser?.id;
    final admins = provider.admins;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addAdmin(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Tambah Admin'),
      ),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: admins.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 80),
                  AppEmptyState(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Belum ada admin',
                    description: 'Tambahkan anggota yang sudah disetujui sebagai admin.',
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: admins.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final admin = admins[i];
                  final isSuper = admin.hasRole('super_admin');
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: (isSuper ? scheme.tertiary : scheme.primary).withValues(alpha: 0.15),
                        child: Icon(
                          isSuper ? Icons.verified_user_rounded : Icons.shield_rounded,
                          color: isSuper ? scheme.tertiary : scheme.primary,
                        ),
                      ),
                      title: Text(
                        admin.name.isEmpty ? admin.email : admin.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${isSuper ? 'Super Admin' : 'Admin'} • ${_summary(provider, admin)}',
                        ),
                      ),
                      isThreeLine: true,
                      onTap: isSuper
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminPermissionEditorScreen(admin: admin),
                                ),
                              ),
                      trailing: isSuper || admin.id == me
                          ? null
                          : PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'perm') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminPermissionEditorScreen(admin: admin),
                                    ),
                                  );
                                } else if (v == 'revoke') {
                                  _revoke(context, admin);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'perm', child: Text('Atur Izin')),
                                PopupMenuItem(value: 'revoke', child: Text('Cabut Role Admin')),
                              ],
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _UserPickerSheet extends StatefulWidget {
  final List<User> users;
  const _UserPickerSheet({required this.users});

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<_UserPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final users = widget.users
        .where((u) => q.isEmpty || u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q))
        .toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Pilih anggota', style: Theme.of(context).textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Cari nama atau email',
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: users.isEmpty
                ? const AppEmptyState(
                    icon: Icons.person_search_rounded,
                    title: 'Tidak ada anggota',
                    description: 'Hanya anggota yang sudah disetujui dan belum menjadi admin yang dapat dipilih.',
                  )
                : ListView.builder(
                    controller: controller,
                    itemCount: users.length,
                    itemBuilder: (context, i) {
                      final u = users[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?')),
                        title: Text(u.name),
                        subtitle: Text(u.email),
                        onTap: () => Navigator.pop(context, u),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Categories
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTab extends StatelessWidget {
  const _CategoryTab();

  Future<void> _add(BuildContext context) async {
    final provider = context.read<AdminAccessProvider>();
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategori Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama kategori',
            hintText: 'mis. Wanita, Musik, Diakonia',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Simpan')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    final error = await provider.addCategory(name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Kategori "${name.trim()}" ditambahkan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminAccessProvider>();
    final categories = provider.categories;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Kategori'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text(
            'Kategori membatasi data yang dapat diakses seorang Admin '
            '(mis. Admin Pemuda hanya data Pemuda). Kategori nonaktif '
            'langsung mencabut izin yang terikat padanya.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final AdminCategory c in categories)
            Card(
              child: SwitchListTile(
                title: Text(c.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Kode: ${c.kode}'),
                value: c.isActive,
                onChanged: (v) => provider.setCategoryActive(c, v),
              ),
            ),
          if (categories.isEmpty)
            const AppEmptyState(
              icon: Icons.category_outlined,
              title: 'Belum ada kategori',
              description: 'Jalankan migrasi RBAC v2 untuk membuat kategori awal.',
            ),
        ],
      ),
    );
  }
}

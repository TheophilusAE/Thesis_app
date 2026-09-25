import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/user.dart';
import '../utils/app_theme.dart';
import 'admin_management_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showEditSheet(BuildContext context, User user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _EditProfileSheet(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profil',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, tp, _) => IconButton(
              icon: Icon(
                tp.themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Ganti tema',
              onPressed: tp.toggleTheme,
            ),
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final user = auth.currentUser;
              if (user == null) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(Icons.edit_rounded, color: theme.colorScheme.onSurface),
                tooltip: 'Edit profil',
                onPressed: () => _showEditSheet(context, user),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.currentUser == null) {
            return const Center(child: Text('Tidak ada data user'));
          }
          return _ProfileBody(user: auth.currentUser!);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Profile body
// ─────────────────────────────────────────────

class ProfileView extends StatelessWidget {
  final User user;
  const ProfileView({super.key, required this.user});

  @override
  Widget build(BuildContext context) => _ProfileBody(user: user);
}

class _ProfileBody extends StatelessWidget {
  final User user;
  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _ProfileHeader(user: user),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              children: [
                _InfoCard(
                  title: 'Informasi Pribadi',
                  icon: Icons.person_outline_rounded,
                  items: [
                    _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
                    _InfoRow(icon: Icons.phone_outlined, label: 'Telepon', value: user.phone.isNotEmpty ? user.phone : '-'),
                    _InfoRow(icon: Icons.home_outlined, label: 'Alamat', value: user.address ?? '-'),
                  ],
                ),
                const SizedBox(height: 14),
                _InfoCard(
                  title: 'Informasi Keanggotaan',
                  icon: Icons.church_rounded,
                  items: [
                    _InfoRow(
                      icon: Icons.card_membership_rounded,
                      label: 'No. Kartu Jemaat',
                      value: user.memberCardNumber ?? '-',
                    ),
                    _InfoRow(
                      icon: Icons.water_drop_outlined,
                      label: 'Tanggal Baptis',
                      value: user.baptismDate ?? '-',
                    ),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'No. Identitas (NIK)',
                      value: user.identityNumber ?? '-',
                    ),
                    _InfoRow(
                      icon: Icons.group_outlined,
                      label: 'Kelompok Keluarga',
                      value: user.familyGroup ?? '-',
                    ),
                    _InfoRow(
                      icon: Icons.event_available_rounded,
                      label: 'Anggota Sejak',
                      value: user.memberSince ?? '-',
                    ),
                  ],
                ),
                if (user.identityNumber == null ||
                    user.familyGroup == null ||
                    user.baptismDate == null ||
                    user.address == null) ...[
                  const SizedBox(height: 14),
                  _ActionButton(
                    icon: Icons.assignment_ind_outlined,
                    label: 'Lengkapi Data Jemaat',
                    color: Theme.of(context).colorScheme.primary,
                    outlined: true,
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (ctx) => Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                        child: _EditProfileSheet(user: user),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (context.watch<AuthProvider>().isAdminMode) ...[
                  _ActionButton(
                    icon: Icons.manage_accounts_rounded,
                    label: 'Kelola Data Pengguna',
                    color: Theme.of(context).colorScheme.primary,
                    outlined: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminManagementScreen()),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _ActionButton(
                  icon: Icons.logout_rounded,
                  label: 'Keluar',
                  color: AppTheme.errorColor,
                  outlined: true,
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.darkCharcoal,
                    side: const BorderSide(color: AppTheme.neutralBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final auth = context.read<AuthProvider>();
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
                    }
                  },
                  child: const Text('Keluar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Profile header
// ─────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final User user;
  const _ProfileHeader({required this.user});

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      default:
        return AppTheme.errorColor;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'pelayan':
        return 'Pelayan';
      default:
        return 'Jemaat';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: IgnorePointer(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.secondary.withValues(alpha: 0.16),
                      AppTheme.secondary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -30,
            child: IgnorePointer(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.08),
                      AppTheme.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              // Avatar with warm gold ring
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.goldGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gold.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: theme.colorScheme.surface,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 32,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                user.email,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  ...user.roles.map(
                    (r) => _HeaderChip(
                      label: _roleLabel(r),
                      icon: r == 'admin'
                          ? Icons.shield_rounded
                          : r == 'pelayan'
                              ? Icons.church_rounded
                              : Icons.person_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                  _HeaderChip(
                    label: _statusLabel(user.membershipStatus),
                    icon: Icons.verified_rounded,
                    color: _statusColor(user.membershipStatus),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _HeaderChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Info card
// ─────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoRow> items;

  const _InfoCard({required this.title, required this.icon, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: AppTheme.subtleCardDecoration(radius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            return Column(
              children: [
                entry.value,
                if (!isLast)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 18, color: secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall?.copyWith(color: secondary)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Action button
// ─────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.outlined,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Edit profile bottom sheet
// ─────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final User user;
  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _nikCtrl;
  late final TextEditingController _familyGroupCtrl;
  String? _baptism;
  bool _saving = false;

  static String? _blankToNull(String v) => v.trim().isEmpty ? null : v.trim();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _addressCtrl = TextEditingController(text: widget.user.address ?? '');
    _nikCtrl = TextEditingController(text: widget.user.identityNumber ?? '');
    _familyGroupCtrl = TextEditingController(text: widget.user.familyGroup ?? '');
    final b = widget.user.baptismDate;
    _baptism = (b == 'Sudah' || b == 'Belum') ? b : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _nikCtrl.dispose();
    _familyGroupCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong')),
      );
      return;
    }

    // NIK is optional, but if provided it must be a 16-digit number.
    final nik = _nikCtrl.text.trim();
    if (nik.isNotEmpty && !RegExp(r'^\d{16}$').hasMatch(nik)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NIK harus 16 digit angka')),
      );
      return;
    }

    setState(() => _saving = true);

    final u = widget.user;
    // Built directly (not copyWith) so cleared optional fields become null.
    final updatedUser = User(
      id: u.id,
      name: name,
      email: u.email,
      phone: _phoneCtrl.text.trim(),
      roles: u.roles,
      membershipStatus: u.membershipStatus,
      identityNumber: _blankToNull(nik),
      familyGroup: _blankToNull(_familyGroupCtrl.text),
      membershipType: u.membershipType,
      memberCardNumber: u.memberCardNumber,
      profileImage: u.profileImage,
      address: _blankToNull(_addressCtrl.text),
      birthDate: u.birthDate,
      baptismDate: _baptism,
      memberSince: u.memberSince,
    );

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(updatedUser);

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profil berhasil diperbarui'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui profil. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit Profil & Lengkapi Data Jemaat',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Nomor Telepon',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _nikCtrl,
            decoration: const InputDecoration(
              labelText: 'Nomor Identitas (NIK / KTP) (opsional)',
              prefixIcon: Icon(Icons.credit_card_outlined),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _familyGroupCtrl,
            decoration: const InputDecoration(
              labelText: 'Kelompok Keluarga / Komsel (opsional)',
              prefixIcon: Icon(Icons.groups_outlined),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _baptism,
            decoration: const InputDecoration(
              labelText: 'Status Baptis Selam (opsional)',
              prefixIcon: Icon(Icons.water_drop_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'Belum', child: Text('Belum Dibaptis Selam')),
              DropdownMenuItem(value: 'Sudah', child: Text('Sudah Dibaptis Selam')),
            ],
            onChanged: (v) => setState(() => _baptism = v),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _addressCtrl,
            decoration: const InputDecoration(
              labelText: 'Alamat Domisili (opsional)',
              prefixIcon: Icon(Icons.home_outlined),
              alignLabelWithHint: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// Keep EditProfileForm alias for backward compatibility
class EditProfileForm extends StatelessWidget {
  final User user;
  final VoidCallback onSave;
  const EditProfileForm({super.key, required this.user, required this.onSave});

  @override
  Widget build(BuildContext context) => _EditProfileSheet(user: user);
}

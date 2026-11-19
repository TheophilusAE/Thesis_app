import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/checkin_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/app_theme.dart';

/// "Hapus Akun": explains what is deleted, asks the user to type HAPUS, then
/// deletes the account server-side (Edge Function `delete-account`) and
/// returns to the guest home. Required by Google Play for apps with sign-up.
Future<void> showDeleteAccountDialog(BuildContext context) async {
  final deleted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const DeleteAccountDialog(),
  );
  if (deleted != true || !context.mounted) return;
  context.read<NotificationProvider>().clearForSignOut();
  context.read<CheckinProvider>().clear();
  final messenger = ScaffoldMessenger.of(context);
  Navigator.of(context).popUntil((route) => route.isFirst);
  messenger.showSnackBar(const SnackBar(content: Text('Akun Anda telah dihapus.')));
}

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  static const confirmWord = 'HAPUS';

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _confirmed => _ctrl.text.trim().toUpperCase() == DeleteAccountDialog.confirmWord;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final ok = await auth.deleteAccount();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = auth.lastMessage ?? 'Gagal menghapus akun.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = context.read<AuthProvider>().isSuperAdmin;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.delete_forever_rounded, color: AppTheme.errorColor),
          const SizedBox(width: 8),
          const Expanded(child: Text('Hapus Akun', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSuperAdmin)
              const Text(
                'Akun Super Admin tidak dapat dihapus sendiri. Serahkan peran Super Admin '
                'ke akun lain terlebih dahulu.',
              )
            else ...[
              const Text(
                'Akun dan data pribadi Anda akan dihapus permanen dan tidak dapat dikembalikan:',
              ),
              const SizedBox(height: 8),
              const Text(
                '• Login, profil (nama, email, telepon, alamat, tanggal lahir)\n'
                '• Notifikasi, kehadiran, pendaftaran event\n'
                '• Permintaan doa, feedback, permintaan penggantian',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Jadwal, event, atau catatan kas yang Anda buat sebagai pengurus tetap tersimpan '
                'tanpa tautan ke akun Anda.',
                style: TextStyle(fontSize: 13, color: AppTheme.mutedCharcoal),
              ),
              const SizedBox(height: 16),
              Text('Ketik ${DeleteAccountDialog.confirmWord} untuk melanjutkan:'),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('delete-confirm-field'),
                controller: _ctrl,
                enabled: !_busy,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: DeleteAccountDialog.confirmWord),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        if (!isSuperAdmin)
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white),
            onPressed: _confirmed && !_busy ? _delete : null,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Hapus Permanen'),
          ),
      ],
    );
  }
}

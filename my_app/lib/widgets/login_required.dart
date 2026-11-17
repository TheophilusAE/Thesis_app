import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../screens/register_screen.dart';

/// Opens the login screen on top of the current route (guest mode).
/// After a successful login the login screen pops back to the root, where
/// `_AuthGate` swaps the guest home for the signed-in home.
Future<void> openLogin(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
}

Future<void> openRegister(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const RegisterScreen()),
  );
}

/// Explains to a guest that [feature] needs an account and offers to sign
/// in or register. Personal data is never shown or stored for guests.
Future<void> showLoginRequired(BuildContext context, {required String feature}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.lock_person_rounded),
      title: const Text('Perlu Akun Jemaat'),
      content: Text(
        '$feature hanya tersedia untuk jemaat yang sudah terdaftar dan disetujui. '
        'Silakan masuk, atau daftar terlebih dahulu.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Nanti')),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            openRegister(context);
          },
          child: const Text('Daftar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            openLogin(context);
          },
          child: const Text('Masuk'),
        ),
      ],
    ),
  );
}

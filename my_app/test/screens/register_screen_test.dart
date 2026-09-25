import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/screens/register_screen.dart';
import 'package:my_app/services/supabase_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockService extends Mock implements SupabaseService {}

void main() {
  testWidgets('registration asks only for name, email, phone and password', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: AuthProvider(service: _MockService()),
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );

    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Alamat Email'), findsOneWidget);
    expect(find.text('Nomor WhatsApp / HP'), findsOneWidget);
    expect(find.text('Kata Sandi Akun'), findsOneWidget);
    expect(find.text('Nomor Identitas (NIK / KTP)'), findsNothing);
    expect(find.text('Data Jemaat & Domisili'), findsNothing);
    expect(find.text('Daftar Sebagai Jemaat'), findsOneWidget);
  });
}

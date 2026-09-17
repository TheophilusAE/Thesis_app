import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/komsel_provider.dart';
import 'package:my_app/screens/komsel_directory_screen.dart';
import 'package:my_app/services/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  testWidgets('shows the empty state when there are no active komsel', (tester) async {
    final mockService = MockSupabaseService();
    when(() => mockService.getActiveKomsels()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      ChangeNotifierProvider<KomselProvider>(
        create: (_) => KomselProvider(service: mockService),
        child: const MaterialApp(home: KomselDirectoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Komsel / Kelompok Sel'), findsOneWidget);
    expect(find.text('Belum ada komsel yang terdaftar'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/auth_provider.dart';
import 'package:my_app/providers/prayer_request_provider.dart';
import 'package:my_app/screens/prayer_request_screen.dart';
import 'package:my_app/services/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  testWidgets('renders the submit form and empty state when signed out', (tester) async {
    final mockService = MockSupabaseService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: AuthProvider()),
          ChangeNotifierProvider<PrayerRequestProvider>.value(
            value: PrayerRequestProvider(service: mockService),
          ),
        ],
        child: const MaterialApp(home: PrayerRequestScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Doa & Permohonan'), findsOneWidget);
    expect(find.text('Sampaikan Permohonan Doa'), findsOneWidget);
    expect(find.text('Belum ada permohonan doa'), findsOneWidget);
  });
}

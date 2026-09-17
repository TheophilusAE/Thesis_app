import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/sermon_provider.dart';
import 'package:my_app/screens/sermon_library_screen.dart';
import 'package:my_app/services/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  testWidgets('shows the empty state when there are no active sermons', (tester) async {
    final mockService = MockSupabaseService();
    when(() => mockService.getActiveSermons()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      ChangeNotifierProvider<SermonProvider>(
        create: (_) => SermonProvider(service: mockService),
        child: const MaterialApp(home: SermonLibraryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khotbah & Media Rohani'), findsOneWidget);
    expect(find.text('Belum ada khotbah yang tersedia'), findsOneWidget);
  });
}

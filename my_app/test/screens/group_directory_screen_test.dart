import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:my_app/providers/group_provider.dart';
import 'package:my_app/screens/group_directory_screen.dart';
import 'package:my_app/services/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  testWidgets('shows the empty state when there are no active group', (tester) async {
    final mockService = MockSupabaseService();
    when(() => mockService.getActiveGroups()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      ChangeNotifierProvider<GroupProvider>(
        create: (_) => GroupProvider(service: mockService),
        child: const MaterialApp(home: GroupDirectoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Group'), findsOneWidget);
    expect(find.text('Belum ada group yang terdaftar'), findsOneWidget);
  });
}

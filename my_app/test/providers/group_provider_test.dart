import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/models/church_group.dart';
import 'package:my_app/providers/group_provider.dart';
import 'package:my_app/services/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  late MockSupabaseService mockService;
  late GroupProvider provider;

  setUp(() {
    mockService = MockSupabaseService();
    provider = GroupProvider(service: mockService);
  });

  test('loadActiveGroups populates activeGroups from the service', () async {
    when(() => mockService.getActiveGroups()).thenAnswer((_) async => [
          {'id': 'k1', 'nama': 'Group A', 'is_active': true, 'created_at': '2026-01-01T00:00:00.000Z'},
        ]);

    await provider.loadActiveGroups();

    expect(provider.activeGroups, hasLength(1));
    expect(provider.activeGroups.first.nama, 'Group A');
  });

  test('addGroup inserts the created row at the front of allGroups', () async {
    when(() => mockService.addGroup(any())).thenAnswer((invocation) async {
      final data = invocation.positionalArguments.first as Map<String, dynamic>;
      return {'id': 'k2', 'created_at': '2026-01-02T00:00:00.000Z', ...data};
    });

    final churchGroup = ChurchGroup(id: '', nama: 'Group B', createdAt: DateTime.now());
    final success = await provider.addGroup(churchGroup);

    expect(success, isTrue);
    expect(provider.allGroups, hasLength(1));
    expect(provider.allGroups.first.nama, 'Group B');
  });

  test('deleteGroup removes the group from both lists', () async {
    when(() => mockService.getGroups()).thenAnswer((_) async => [
          {'id': 'k3', 'nama': 'Group C', 'created_at': '2026-01-01T00:00:00.000Z'},
        ]);
    when(() => mockService.deleteGroup(any())).thenAnswer((_) async {});

    await provider.loadAllGroups();
    final success = await provider.deleteGroup('k3');

    expect(success, isTrue);
    expect(provider.allGroups, isEmpty);
  });
}

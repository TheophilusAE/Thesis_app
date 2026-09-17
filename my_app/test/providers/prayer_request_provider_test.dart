import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/providers/prayer_request_provider.dart';
import 'package:my_app/services/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  late MockSupabaseService mockService;
  late PrayerRequestProvider provider;

  setUp(() {
    mockService = MockSupabaseService();
    provider = PrayerRequestProvider(service: mockService);
  });

  test('loadMyRequests populates myRequests from the service', () async {
    when(() => mockService.getMyPrayerRequests(any())).thenAnswer((_) async => [
          {
            'id': 'pr-1',
            'user_id': 'u1',
            'content': 'Doa 1',
            'status': 'baru',
            'created_at': '2026-01-01T00:00:00.000Z',
          },
        ]);

    await provider.loadMyRequests('u1');

    expect(provider.myRequests, hasLength(1));
    expect(provider.myRequests.first.content, 'Doa 1');
    expect(provider.isLoading, isFalse);
  });

  test('submitRequest inserts the created row at the front of myRequests', () async {
    when(() => mockService.addPrayerRequest(any())).thenAnswer((invocation) async {
      final data = invocation.positionalArguments.first as Map<String, dynamic>;
      return {'id': 'pr-2', 'created_at': '2026-01-02T00:00:00.000Z', ...data};
    });

    final success = await provider.submitRequest(
      userId: 'u1',
      userName: 'Budi',
      category: 'pribadi',
      content: 'Doa baru',
    );

    expect(success, isTrue);
    expect(provider.myRequests, hasLength(1));
    expect(provider.myRequests.first.content, 'Doa baru');
  });

  test('updateStatus patches the matching request in both lists', () async {
    when(() => mockService.getAllPrayerRequests()).thenAnswer((_) async => [
          {
            'id': 'pr-3',
            'user_id': 'u2',
            'content': 'Doa 3',
            'status': 'baru',
            'created_at': '2026-01-01T00:00:00.000Z',
          },
        ]);
    when(() => mockService.updatePrayerRequest(any(), any())).thenAnswer((_) async {});

    await provider.loadAllRequests();
    final success = await provider.updateStatus('pr-3', 'terjawab');

    expect(success, isTrue);
    expect(provider.allRequests.first.status, 'terjawab');
  });

  test('deleteRequest removes the request from local state', () async {
    when(() => mockService.getMyPrayerRequests(any())).thenAnswer((_) async => [
          {
            'id': 'pr-4',
            'user_id': 'u1',
            'content': 'Doa 4',
            'created_at': '2026-01-01T00:00:00.000Z',
          },
        ]);
    when(() => mockService.deletePrayerRequest(any())).thenAnswer((_) async {});

    await provider.loadMyRequests('u1');
    final success = await provider.deleteRequest('pr-4');

    expect(success, isTrue);
    expect(provider.myRequests, isEmpty);
  });
}

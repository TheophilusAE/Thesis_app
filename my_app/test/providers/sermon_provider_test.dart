import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/models/sermon.dart';
import 'package:my_app/providers/sermon_provider.dart';
import 'package:my_app/services/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  late MockSupabaseService mockService;
  late SermonProvider provider;

  setUp(() {
    mockService = MockSupabaseService();
    provider = SermonProvider(service: mockService);
  });

  test('loadActiveSermons populates activeSermons from the service', () async {
    when(() => mockService.getActiveSermons()).thenAnswer((_) async => [
          {
            'id': 's1',
            'title': 'Khotbah A',
            'media_url': 'https://youtu.be/abc',
            'sermon_date': '2026-01-01T00:00:00.000Z',
            'created_at': '2026-01-01T00:00:00.000Z',
          },
        ]);

    await provider.loadActiveSermons();

    expect(provider.activeSermons, hasLength(1));
    expect(provider.activeSermons.first.title, 'Khotbah A');
  });

  test('addSermon inserts the created row at the front of allSermons', () async {
    when(() => mockService.addSermon(any())).thenAnswer((invocation) async {
      final data = invocation.positionalArguments.first as Map<String, dynamic>;
      return {'id': 's2', 'created_at': '2026-01-02T00:00:00.000Z', ...data};
    });

    final sermon = Sermon(
      id: '',
      title: 'Khotbah B',
      mediaUrl: 'https://youtu.be/xyz',
      sermonDate: DateTime.now(),
      createdAt: DateTime.now(),
    );
    final success = await provider.addSermon(sermon);

    expect(success, isTrue);
    expect(provider.allSermons, hasLength(1));
    expect(provider.allSermons.first.title, 'Khotbah B');
  });

  test('deleteSermon removes it from both lists', () async {
    when(() => mockService.getSermons()).thenAnswer((_) async => [
          {
            'id': 's3',
            'title': 'Khotbah C',
            'media_url': 'https://youtu.be/c',
            'sermon_date': '2026-01-01T00:00:00.000Z',
            'created_at': '2026-01-01T00:00:00.000Z',
          },
        ]);
    when(() => mockService.deleteSermon(any())).thenAnswer((_) async {});

    await provider.loadAllSermons();
    final success = await provider.deleteSermon('s3');

    expect(success, isTrue);
    expect(provider.allSermons, isEmpty);
  });
}

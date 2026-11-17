import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/providers/recommendation_provider.dart';
import 'package:my_app/services/recommendation_engine.dart';
import 'package:my_app/services/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  late MockSupabaseService service;

  setUp(() => service = MockSupabaseService());

  test('generate reads schedules, attendance and feedback and runs the engine', () async {
    when(() => service.getSchedules()).thenAnswer((_) async => [
          for (var i = 0; i < 3; i++)
            {
              'id': 's$i',
              'pelayan_id': 'p1',
              'service_date': DateTime(2026, 6, 7 + 7 * i).toIso8601String(),
              'service_type': 'Ibadah Minggu',
            },
        ]);
    when(() => service.getAllAttendance()).thenAnswer((_) async => [
          for (var i = 0; i < 3; i++)
            for (var u = 0; u < 95; u++)
              {
                'id': 'a$i-$u',
                'user_id': 'u$u',
                'service_schedule_id': 's$i',
                'schedule_date': DateTime(2026, 6, 7 + 7 * i).toIso8601String(),
                'confirmed': true,
              },
        ]);
    when(() => service.getAllFeedback()).thenAnswer((_) async => []);

    final provider = RecommendationProvider(
      service: service,
      eventLoader: (_) async => const [],
      buildingCapacity: 100,
    );
    await provider.generate(now: DateTime(2026, 6, 30));

    expect(provider.error, isNull);
    expect(provider.isLoading, isFalse);
    final result = provider.result!;
    expect(result.summary.serviceOccurrences, 3);
    expect(result.summary.buildingCapacity, 100);
    expect(
      result.recommendations.any((r) =>
          r.category == RecommendationCategory.kapasitas &&
          r.severity == RecommendationSeverity.warning),
      isTrue,
    );
  });

  test('a load failure surfaces a friendly error instead of empty results', () async {
    when(() => service.getSchedules()).thenThrow(Exception('rls'));
    when(() => service.getAllAttendance()).thenAnswer((_) async => []);
    when(() => service.getAllFeedback()).thenAnswer((_) async => []);

    final provider = RecommendationProvider(
      service: service,
      eventLoader: (_) async => const [],
      buildingCapacity: null,
    );
    await provider.generate();

    expect(provider.result, isNull);
    expect(provider.error, contains('Gagal memuat data'));
  });

  test('defaults to the configured building capacity (null until the church sets it)', () {
    final provider = RecommendationProvider(service: service, eventLoader: (_) async => const []);
    expect(provider.buildingCapacity, isNull);
  });
}

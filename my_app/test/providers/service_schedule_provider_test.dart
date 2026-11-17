import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/providers/service_schedule_provider.dart';
import 'package:my_app/services/supabase_service.dart';
import 'package:my_app/utils/recurrence.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  late MockSupabaseService service;
  late ServiceScheduleProvider provider;
  var counter = 0;

  setUp(() {
    service = MockSupabaseService();
    provider = ServiceScheduleProvider(service: service);
    counter = 0;
    when(() => service.addSchedule(any())).thenAnswer((inv) async {
      final data = inv.positionalArguments.first as Map<String, dynamic>;
      return {...data, 'id': 'row-${counter++}'};
    });
  });

  Future<ScheduleCreateResult> create({required bool recurring, String pattern = recurrenceWeekly}) =>
      provider.addServiceSchedule(
        pelayaniId: 'pel-1',
        pelayaniName: 'Andi',
        pelayaniPosition: 'Usher',
        serviceDate: DateTime(2026, 1, 4),
        startTime: '08:00',
        endTime: '10:00',
        serviceType: 'Ibadah Minggu',
        isRecurring: recurring,
        recurringPattern: pattern,
      );

  test('a one-off schedule creates exactly one row with an empty pattern', () async {
    final result = await create(recurring: false);

    expect(result.created, hasLength(1));
    expect(result.allSaved, isTrue);
    final payload = verify(() => service.addSchedule(captureAny())).captured.single
        as Map<String, dynamic>;
    expect(payload['is_recurring'], isFalse);
    expect(payload['recurring_pattern'], '');
  });

  test('a weekly schedule materializes one row per occurrence', () async {
    final result = await create(recurring: true);

    final expected = generateRecurrenceDates(DateTime(2026, 1, 4), recurrenceWeekly);
    expect(result.requested, expected.length);
    expect(result.created, hasLength(expected.length));
    expect(provider.allSchedules, hasLength(expected.length));
    final payloads = verify(() => service.addSchedule(captureAny())).captured.cast<Map<String, dynamic>>();
    expect(payloads.every((p) => p['is_recurring'] == true && p['recurring_pattern'] == 'WEEKLY'),
        isTrue);
  });

  test('re-creating the same series skips every duplicate occurrence', () async {
    await create(recurring: true);
    clearInteractions(service);

    final again = await create(recurring: true);

    expect(again.created, isEmpty);
    expect(again.skippedDuplicates, again.requested);
    expect(again.allSaved, isTrue);
    verifyNever(() => service.addSchedule(any()));
  });

  test('stops at the first failed insert and reports a partial result', () async {
    var calls = 0;
    when(() => service.addSchedule(any())).thenAnswer((inv) async {
      if (calls++ == 2) throw Exception('network');
      final data = inv.positionalArguments.first as Map<String, dynamic>;
      return {...data, 'id': 'row-$calls'};
    });

    final result = await create(recurring: true);

    expect(result.created, hasLength(2));
    expect(result.anySaved, isTrue);
    expect(result.allSaved, isFalse);
    expect(provider.error, contains('network'));
  });
}

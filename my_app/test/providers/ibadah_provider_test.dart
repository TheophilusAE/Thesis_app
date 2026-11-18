import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/models/ibadah.dart';
import 'package:my_app/models/pelayan.dart';
import 'package:my_app/providers/ibadah_provider.dart';
import 'package:my_app/services/supabase_service.dart';
import 'package:my_app/utils/recurrence.dart';

class _MockService extends Mock implements SupabaseService {}

IbadahSeries _series({
  String pola = recurrenceWeekly,
  DateTime? start,
  DateTime? end,
  bool active = true,
}) =>
    IbadahSeries(
      id: 's1',
      nama: 'Ibadah Raya',
      jenis: 'Ibadah Umum',
      pola: pola,
      startDate: start ?? DateTime(2026, 1, 4), // a Sunday
      endDate: end,
      startTime: '07:00',
      endTime: '09:00',
      isActive: active,
    );

IbadahOccurrence _occ() => IbadahOccurrence(
      id: 'occ-1',
      seriesId: 's1',
      tanggal: DateTime(2026, 11, 22),
      startTime: '07:00',
      endTime: '09:00',
      lokasi: 'Gedung Utama',
      nama: 'Ibadah Raya',
      jenis: 'Ibadah Umum',
    );

Pelayan _p(String id, {String userId = ''}) => Pelayan(
      id: id,
      userId: userId,
      nama: 'Pelayan $id',
      noTelepon: '',
      posisi: 'Usher',
      isAktif: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  group('IbadahDates.forNewSeries', () {
    test('a one-off schedule creates exactly one date', () {
      final d = IbadahDates.forNewSeries(start: DateTime(2026, 12, 25, 15), pola: polaNone);
      expect(d, [DateTime(2026, 12, 25)]);
    });

    test('a weekly schedule creates every 7 days for 90 days, cut at the end date', () {
      final all = IbadahDates.forNewSeries(start: DateTime(2026, 1, 4), pola: recurrenceWeekly);
      expect(all.length, 13);
      expect(all.every((d) => d.weekday == DateTime.sunday), isTrue);

      final cut = IbadahDates.forNewSeries(
          start: DateTime(2026, 1, 4), pola: recurrenceWeekly, endDate: DateTime(2026, 1, 25));
      expect(cut, [DateTime(2026, 1, 4), DateTime(2026, 1, 11), DateTime(2026, 1, 18), DateTime(2026, 1, 25)]);
    });
  });

  group('IbadahDates.upcomingForSeries (rolling horizon)', () {
    test('only future dates, keeping the original weekday', () {
      final d = IbadahDates.upcomingForSeries(_series(), today: DateTime(2026, 11, 18));
      expect(d, isNotEmpty);
      expect(d.first, DateTime(2026, 11, 22));
      expect(d.every((x) => x.weekday == DateTime.sunday), isTrue);
      expect(d.last.isAfter(DateTime(2027, 2, 16)), isFalse);
    });

    test('respects the end date and ignores one-off or inactive series', () {
      expect(
        IbadahDates.upcomingForSeries(_series(end: DateTime(2026, 12, 6)), today: DateTime(2026, 11, 18)),
        [DateTime(2026, 11, 22), DateTime(2026, 11, 29), DateTime(2026, 12, 6)],
      );
      expect(IbadahDates.upcomingForSeries(_series(pola: polaNone), today: DateTime(2026, 11, 18)), isEmpty);
      expect(IbadahDates.upcomingForSeries(_series(active: false), today: DateTime(2026, 11, 18)), isEmpty);
    });
  });

  group('IbadahProvider', () {
    late _MockService service;
    late IbadahProvider provider;

    setUp(() {
      service = _MockService();
      provider = IbadahProvider(service: service);
      when(() => service.getIbadahOccurrences(any(), any())).thenAnswer((_) async => []);
      when(() => service.getIbadahSeries()).thenAnswer((_) async => []);
      registerFallbackValue(<DateTime>[]);
      registerFallbackValue(<String, dynamic>{});
    });

    test('creating a series sends its fields and all generated dates in one call', () async {
      when(() => service.createIbadahSeries(any(), any())).thenAnswer((_) async => 'new-id');

      final error = await provider.createSeries(_series(start: DateTime(2026, 1, 4)));

      expect(error, isNull);
      final captured = verify(() => service.createIbadahSeries(captureAny(), captureAny())).captured;
      final json = captured[0] as Map<String, dynamic>;
      final dates = captured[1] as List<DateTime>;
      expect(json['nama'], 'Ibadah Raya');
      expect(json['pola'], recurrenceWeekly);
      expect(json['start_date'], '2026-01-04');
      expect(dates.length, 13);
    });

    test('a refused create returns the database message', () async {
      when(() => service.createIbadahSeries(any(), any())).thenThrow(
          Exception('message: Anda tidak memiliki izin membuat jadwal ibadah untuk kategori ini., code: 42501'));

      final error = await provider.createSeries(_series());

      expect(error, contains('tidak memiliki izin'));
    });

    test('assigning pelayan links each duty to the worship date (no retyped date/place)', () async {
      when(() => service.addSchedule(any())).thenAnswer((inv) async => inv.positionalArguments.first as Map<String, dynamic>);
      when(() => service.addTrainingSchedule(any())).thenAnswer((inv) async => inv.positionalArguments.first as Map<String, dynamic>);

      final error = await provider.assignPelayanan(
        occurrence: _occ(),
        pelayan: [_p('p1'), _p('p2')],
        rehearsal: RehearsalInput(date: DateTime(2026, 11, 21, 12), startTime: '18:00', endTime: '20:00'),
      );

      expect(error, isNull);
      final duties = verify(() => service.addSchedule(captureAny())).captured.cast<Map<String, dynamic>>();
      expect(duties.map((d) => d['pelayan_id']), ['p1', 'p2']);
      expect(duties.every((d) => d['occurrence_id'] == 'occ-1'), isTrue);

      final training = verify(() => service.addTrainingSchedule(captureAny())).captured.single as Map<String, dynamic>;
      expect(training['occurrence_id'], 'occ-1');
      expect(training['pelayan_ids'], ['p1', 'p2']);
      expect(training['lokasi'], 'Gedung Utama'); // defaults to the worship place
    });

    test('assigning nobody is rejected before calling the server', () async {
      final error = await provider.assignPelayanan(occurrence: _occ(), pelayan: const []);
      expect(error, isNotNull);
      verifyNever(() => service.addSchedule(any()));
    });

    test('a missing table reports that the migration has to run', () async {
      when(() => service.getIbadahOccurrences(any(), any()))
          .thenThrow(Exception('PGRST205 Could not find the table ibadah_schedule_view'));

      await provider.load();

      expect(provider.error, contains('migration_scheduling_v2.sql'));
    });
  });
}

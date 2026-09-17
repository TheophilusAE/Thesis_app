import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/attendance_confirmation.dart';

void main() {
  group('AttendanceConfirmation', () {
    test('fromJson defaults check_in_method to manual when absent', () {
      final json = {
        'id': 'att-1',
        'user_id': 'u1',
        'user_name': 'Budi',
        'service_schedule_id': 's1',
        'schedule_date': '2026-01-05T07:00:00.000Z',
        'confirmed': true,
        'created_at': '2026-01-01T00:00:00.000Z',
      };

      final confirmation = AttendanceConfirmation.fromJson(json);

      expect(confirmation.checkInMethod, 'manual');
      expect(confirmation.checkedInBy, isNull);
    });

    test('fromJson/toJson round trip including QR fields', () {
      final json = {
        'id': 'att-2',
        'user_id': 'u2',
        'user_name': 'Siti',
        'service_schedule_id': 's2',
        'schedule_date': '2026-01-05T07:00:00.000Z',
        'confirmed': true,
        'confirmed_at': '2026-01-05T07:05:00.000Z',
        'notes': null,
        'check_in_method': 'qr',
        'checked_in_by': 'pelayan-1',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-05T07:05:00.000Z',
      };

      final confirmation = AttendanceConfirmation.fromJson(json);
      expect(confirmation.checkInMethod, 'qr');
      expect(confirmation.checkedInBy, 'pelayan-1');

      final roundTripped = confirmation.toJson();
      expect(roundTripped['check_in_method'], 'qr');
      expect(roundTripped['checked_in_by'], 'pelayan-1');
    });

    test('toSupabaseJson includes check_in_method and checked_in_by', () {
      final confirmation = AttendanceConfirmation(
        id: '',
        userId: 'u3',
        userName: 'Rudi',
        serviceScheduleId: 's3',
        scheduleDate: DateTime.utc(2026, 1, 5, 7),
        confirmed: true,
        confirmedAt: DateTime.utc(2026, 1, 5, 7, 1),
        checkInMethod: 'qr',
        checkedInBy: 'pelayan-2',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final data = confirmation.toSupabaseJson();
      expect(data['check_in_method'], 'qr');
      expect(data['checked_in_by'], 'pelayan-2');
      expect(data.containsKey('id'), isFalse);
    });

    test('copyWith preserves fields not overridden', () {
      final original = AttendanceConfirmation(
        id: 'att-4',
        userId: 'u4',
        userName: 'Ani',
        serviceScheduleId: 's4',
        scheduleDate: DateTime.utc(2026, 1, 5),
        confirmed: false,
        checkInMethod: 'manual',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final updated = original.copyWith(confirmed: true, checkInMethod: 'qr', checkedInBy: 'p1');

      expect(updated.confirmed, isTrue);
      expect(updated.checkInMethod, 'qr');
      expect(updated.checkedInBy, 'p1');
      expect(updated.userName, 'Ani');
    });
  });
}

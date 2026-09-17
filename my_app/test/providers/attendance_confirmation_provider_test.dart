import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/models/attendance_confirmation.dart';
import 'package:my_app/providers/attendance_confirmation_provider.dart';
import 'package:my_app/services/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  late MockSupabaseService mockService;
  late AttendanceConfirmationProvider provider;

  setUp(() {
    mockService = MockSupabaseService();
    provider = AttendanceConfirmationProvider(service: mockService);
  });

  AttendanceConfirmation buildConfirmation({required String checkInMethod, String? checkedInBy}) {
    return AttendanceConfirmation(
      id: '',
      userId: 'u1',
      userName: 'Budi',
      serviceScheduleId: 's1',
      scheduleDate: DateTime.utc(2026, 1, 5, 7),
      confirmed: true,
      confirmedAt: DateTime.utc(2026, 1, 5, 7),
      checkInMethod: checkInMethod,
      checkedInBy: checkedInBy,
      createdAt: DateTime.utc(2026, 1, 5, 7),
    );
  }

  group('createOrUpdateConfirmation', () {
    test('passes check_in_method: qr through to the service on QR check-in', () async {
      when(() => mockService.upsertAttendance(any())).thenAnswer((invocation) async {
        final data = invocation.positionalArguments.first as Map<String, dynamic>;
        return {
          'id': 'att-1',
          ...data,
        };
      });

      final result = await provider.createOrUpdateConfirmation(
        buildConfirmation(checkInMethod: 'qr', checkedInBy: 'pelayan-1'),
      );

      expect(result, isTrue);
      final captured = verify(() => mockService.upsertAttendance(captureAny())).captured.single
          as Map<String, dynamic>;
      expect(captured['check_in_method'], 'qr');
      expect(captured['checked_in_by'], 'pelayan-1');

      expect(provider.allConfirmations, hasLength(1));
      expect(provider.allConfirmations.first.checkInMethod, 'qr');
    });

    test('returns false and records an error when the service call throws', () async {
      when(() => mockService.upsertAttendance(any())).thenThrow(Exception('network error'));

      final result = await provider.createOrUpdateConfirmation(
        buildConfirmation(checkInMethod: 'manual'),
      );

      expect(result, isFalse);
      expect(provider.error, isNotNull);
      expect(provider.allConfirmations, isEmpty);
    });
  });
}

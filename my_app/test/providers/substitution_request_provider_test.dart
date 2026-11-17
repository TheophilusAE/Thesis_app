import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/models/substitution_request.dart';
import 'package:my_app/providers/substitution_request_provider.dart';
import 'package:my_app/services/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

Map<String, dynamic> _row(String id, {String status = 'pending'}) => {
      'id': id,
      'service_schedule_id': 'sched-1',
      'requested_by_user_id': 'requester',
      'requested_by_name': 'Budi',
      'reason': 'Sakit',
      'status': status,
      'requested_replacement_name': 'Andi',
      'created_at': '2026-06-01T00:00:00.000Z',
    };

void main() {
  late MockSupabaseService service;
  late SubstitutionRequestProvider provider;

  setUp(() {
    service = MockSupabaseService();
    provider = SubstitutionRequestProvider(service: service);
  });

  test('approve goes through the atomic review RPC with the chosen replacement pelayan', () async {
    when(() => service.reviewSubstitution(
          requestId: any(named: 'requestId'),
          approve: any(named: 'approve'),
          replacementPelayanId: any(named: 'replacementPelayanId'),
          adminNotes: any(named: 'adminNotes'),
        )).thenAnswer((_) async => {
          'status': 'approved',
          'replacement_user_id': 'replacement-user',
          'replacement_name': 'Andi',
        });
    when(() => service.getSubstitutionRequests()).thenAnswer((_) async => [_row('r1')]);
    await provider.loadAllRequests();

    final ok = await provider.approveRequest(
      requestId: 'r1',
      replacementPelayanId: 'pel-2',
      adminNotes: 'OK',
    );

    expect(ok, isTrue);
    verify(() => service.reviewSubstitution(
          requestId: 'r1',
          approve: true,
          replacementPelayanId: 'pel-2',
          adminNotes: 'OK',
        )).called(1);
    // The client never writes the reviewing admin or the request row itself:
    // the RPC records auth.uid() server-side.
    verifyNever(() => service.updateSubstitutionRequest(any(), any()));

    final updated = provider.allRequests.single;
    expect(updated.status, 'approved');
    expect(updated.replacementUserId, 'replacement-user');
    expect(updated.replacementName, 'Andi');
    expect(provider.pendingCount, 0);
  });

  test('approve returns false (no fake success) when the RPC is refused', () async {
    when(() => service.reviewSubstitution(
          requestId: any(named: 'requestId'),
          approve: any(named: 'approve'),
          replacementPelayanId: any(named: 'replacementPelayanId'),
          adminNotes: any(named: 'adminNotes'),
        )).thenThrow(Exception('Anda tidak memiliki izin meninjau penggantian tugas.'));

    final ok = await provider.approveRequest(requestId: 'r1', replacementPelayanId: 'pel-2');

    expect(ok, isFalse);
    expect(provider.error, contains('izin'));
  });

  test('reject sends approve=false and the reason through the review RPC', () async {
    when(() => service.reviewSubstitution(
          requestId: any(named: 'requestId'),
          approve: any(named: 'approve'),
          replacementPelayanId: any(named: 'replacementPelayanId'),
          adminNotes: any(named: 'adminNotes'),
        )).thenAnswer((_) async => {'status': 'rejected'});

    final ok = await provider.rejectRequest(requestId: 'r1', adminNotes: 'Tidak bisa');

    expect(ok, isTrue);
    verify(() => service.reviewSubstitution(
          requestId: 'r1',
          approve: false,
          replacementPelayanId: null,
          adminNotes: 'Tidak bisa',
        )).called(1);
  });

  test('cancel uses the requester-only cancel RPC', () async {
    when(() => service.cancelSubstitutionRequest(any())).thenAnswer((_) async {});

    final ok = await provider.cancelRequest('r1');

    expect(ok, isTrue);
    verify(() => service.cancelSubstitutionRequest('r1')).called(1);
    verifyNever(() => service.updateSubstitutionRequest(any(), any()));
  });

  test('a new request writes the suggestion to requested_replacement_name', () async {
    when(() => service.addSubstitutionRequest(any())).thenAnswer((inv) async {
      final data = inv.positionalArguments.first as Map<String, dynamic>;
      return {..._row('new'), ...data, 'id': 'new'};
    });

    final ok = await provider.createSubstitutionRequest(SubstitutionRequest(
      id: '',
      serviceScheduleId: 'sched-1',
      requestedByUserId: 'requester',
      requestedByName: 'Budi',
      reason: 'Sakit',
      requestedReplacementName: 'Andi',
      createdAt: DateTime(2026, 6, 1),
    ));

    expect(ok, isTrue);
    final payload = verify(() => service.addSubstitutionRequest(captureAny())).captured.single
        as Map<String, dynamic>;
    expect(payload['requested_replacement_name'], 'Andi');
    expect(payload['replacement_name'], isNull);
  });

  test('hasPendingRequestFor detects a duplicate pending request for the same duty', () async {
    when(() => service.getSubstitutionRequestsByUser('requester')).thenAnswer((_) async => [
          _row('r1'),
          {..._row('r2', status: 'rejected'), 'service_schedule_id': 'sched-2'},
        ]);

    await provider.loadUserRequests('requester');

    expect(provider.hasPendingRequestFor('requester', 'sched-1'), isTrue);
    expect(provider.hasPendingRequestFor('requester', 'sched-2'), isFalse);
    expect(provider.hasPendingRequestFor('someone-else', 'sched-1'), isFalse);
  });
}

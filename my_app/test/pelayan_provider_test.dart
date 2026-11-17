import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/providers/pelayan_provider.dart';
import 'package:my_app/services/supabase_service.dart';

class _MockService extends Mock implements SupabaseService {}

void main() {
  test('loadAllPelayan exposes an error message instead of swallowing it', () async {
    final service = _MockService();
    when(() => service.getPelayans()).thenThrow(Exception('rls'));
    final provider = PelayaniProvider(service: service);

    await provider.loadAllPelayan();

    expect(provider.errorMessage, 'Gagal memuat daftar pelayan.');
    expect(provider.allPelayan, isEmpty);
    expect(provider.isLoading, isFalse);
  });

  test('loadAllPelayan clears the error on success', () async {
    final service = _MockService();
    when(() => service.getPelayans()).thenAnswer((_) async => []);
    final provider = PelayaniProvider(service: service);

    await provider.loadAllPelayan();

    expect(provider.errorMessage, isNull);
  });

  test('addPelayan sends the linked account id, never a placeholder', () async {
    final service = _MockService();
    when(() => service.addPelayan(any())).thenAnswer((_) async => {'id': 'p1'});
    when(() => service.getPelayans()).thenAnswer((_) async => []);
    final provider = PelayaniProvider(service: service);

    final ok = await provider.addPelayan(
      nama: 'Andi',
      noTelepon: '081234567890',
      posisi: 'Usher',
      userId: 'b3f1c2d4-0000-4000-8000-000000000001',
      isAktif: false,
    );

    expect(ok, isTrue);
    final payload = verify(() => service.addPelayan(captureAny())).captured.single
        as Map<String, dynamic>;
    expect(payload['user_id'], 'b3f1c2d4-0000-4000-8000-000000000001');
    expect(payload['is_aktif'], isFalse);
  });

  test('addPelayan without an account sends user_id = null (not "" or "admin-user")', () async {
    final service = _MockService();
    when(() => service.addPelayan(any())).thenAnswer((_) async => {'id': 'p1'});
    when(() => service.getPelayans()).thenAnswer((_) async => []);
    final provider = PelayaniProvider(service: service);

    await provider.addPelayan(nama: 'Andi', noTelepon: '081234567890', posisi: 'Usher', userId: '');

    final payload = verify(() => service.addPelayan(captureAny())).captured.single
        as Map<String, dynamic>;
    expect(payload.containsKey('user_id'), isTrue);
    expect(payload['user_id'], isNull);
  });

  test('pelayanForUser resolves a users.id to its Pelayan record via pelayans.user_id', () async {
    final service = _MockService();
    when(() => service.getPelayans()).thenAnswer((_) async => [
          {'id': 'pel-1', 'user_id': 'user-1', 'nama': 'Andi'},
          {'id': 'pel-2', 'user_id': null, 'nama': 'Tanpa Akun'},
        ]);
    final provider = PelayaniProvider(service: service);
    await provider.loadAllPelayan();

    expect(provider.pelayanForUser('user-1')?.id, 'pel-1');
    expect(provider.pelayanForUser('pel-1'), isNull); // a pelayans.id is not a users.id
    expect(provider.pelayanForUser(null), isNull);
    expect(provider.pelayanForUser(''), isNull);
  });

  test('updatePelayan can link and unlink an account explicitly', () async {
    final service = _MockService();
    when(() => service.updatePelayan(any(), any())).thenAnswer((_) async {});
    final provider = PelayaniProvider(service: service);

    await provider.updatePelayan('pel-1', updateUserLink: true, userId: 'user-9');
    await provider.updatePelayan('pel-1', updateUserLink: true, userId: '');
    await provider.updatePelayan('pel-1', nama: 'Baru');

    final payloads = verify(() => service.updatePelayan('pel-1', captureAny())).captured
        .cast<Map<String, dynamic>>();
    expect(payloads[0]['user_id'], 'user-9');
    expect(payloads[1].containsKey('user_id'), isTrue);
    expect(payloads[1]['user_id'], isNull);
    expect(payloads[2].containsKey('user_id'), isFalse);
  });

  test('id_ID date formatting works after initializeDateFormatting', () async {
    await initializeDateFormatting('id_ID');
    expect(DateFormat('MMMM', 'id_ID').format(DateTime(2026, 8, 1)), 'Agustus');
  });
}

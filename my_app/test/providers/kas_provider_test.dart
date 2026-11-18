import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/models/kas.dart';
import 'package:my_app/providers/kas_provider.dart';
import 'package:my_app/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

class _MockService extends Mock implements SupabaseService {}

Map<String, dynamic> _trx(int id, String jenis, dynamic nominal) => {
      'id': id,
      'kode_transaksi': 'KM-20261118-A1B$id',
      'kas_akun_id': 1,
      'jenis': jenis,
      'kategori': 'Persembahan',
      'tanggal': '2026-11-18',
      'nominal': nominal,
    };

void main() {
  late _MockService service;
  late KasProvider provider;

  setUp(() {
    service = _MockService();
    provider = KasProvider(service: service);
    registerFallbackValue(<String, dynamic>{});
    when(() => service.getKasSaldo()).thenAnswer((_) async => [
          {'id': 1, 'nama_akun': 'Kas Tunai', 'saldo_awal': '100000', 'total_masuk': 50000,
           'total_keluar': '20000.50', 'saldo': 129999.5, 'is_aktif': true},
          {'id': 2, 'nama_akun': 'BCA', 'saldo': 0, 'is_aktif': false},
        ]);
    when(() => service.getKasTransaksi(
          akunId: any(named: 'akunId'),
          jenis: any(named: 'jenis'),
          kategori: any(named: 'kategori'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        )).thenAnswer((_) async => [_trx(1, 'masuk', 50000), _trx(2, 'keluar', '20000.50')]);
  });

  test('numeric columns parse whether PostgREST returns numbers or strings', () async {
    await provider.loadAll();

    expect(provider.akun.first.saldoAwal, 100000);
    expect(provider.akun.first.totalKeluar, 20000.5);
    expect(provider.akunAktif.map((a) => a.namaAkun), ['Kas Tunai']);
    expect(provider.transaksi.last.nominal, 20000.5);
    expect(provider.namaAkun(1), 'Kas Tunai');
  });

  test('the summary totals the filtered list', () async {
    await provider.loadAll();
    final r = provider.ringkasan;
    expect(r.masuk, 50000);
    expect(r.keluar, 20000.5);
    expect(r.selisih, 29999.5);
  });

  test('filters are passed to the query', () async {
    await provider.loadTransaksi(KasFilter(akunId: 1, jenis: KasJenis.keluar, kategori: 'Ops',
        from: DateTime(2026, 11, 1), to: DateTime(2026, 11, 30)));

    verify(() => service.getKasTransaksi(
          akunId: 1,
          jenis: 'keluar',
          kategori: 'Ops',
          from: DateTime(2026, 11, 1),
          to: DateTime(2026, 11, 30),
        )).called(1);
  });

  group('transaction validation (mirrors create_kas_transaksi)', () {
    final today = DateTime(2026, 11, 18);
    String? v({String jenis = 'masuk', String kategori = 'Persembahan', DateTime? tanggal, num nominal = 1000}) =>
        KasProvider.validateTransaksi(
            jenis: jenis, kategori: kategori, tanggal: tanggal ?? today, nominal: nominal, today: today);

    test('accepts a normal entry', () => expect(v(), isNull));
    test('rejects zero or negative amounts', () {
      expect(v(nominal: 0), isNotNull);
      expect(v(nominal: -5), isNotNull);
    });
    test('rejects an empty category and unknown type', () {
      expect(v(kategori: '  '), isNotNull);
      expect(v(jenis: 'transfer'), isNotNull);
    });
    test('rejects future dates', () => expect(v(tanggal: DateTime(2026, 11, 19)), isNotNull));
  });

  test('creating a transaction goes through the RPC (code & recorder set server-side)', () async {
    when(() => service.createKasTransaksi(any())).thenAnswer((_) async => {'id': 9, 'kode_transaksi': 'KK-20261101-9F2C'});

    final error = await provider.createTransaksi(
      kasAkunId: 1, jenis: 'keluar', kategori: ' Operasional ', tanggal: DateTime(2026, 11, 1), nominal: 75000);

    expect(error, isNull);
    final sent = verify(() => service.createKasTransaksi(captureAny())).captured.single as Map<String, dynamic>;
    expect(sent['kas_akun_id'], 1);
    expect(sent['kategori'], 'Operasional');
    expect(sent['tanggal'], '2026-11-01');
    expect(sent.containsKey('kode_transaksi'), isFalse);
    expect(sent.containsKey('dicatat_oleh'), isFalse);
  });

  test('a permission refusal from the database is shown to the admin', () async {
    when(() => service.createKasTransaksi(any())).thenThrow(const PostgrestException(
        message: 'Anda tidak memiliki izin mencatat transaksi pada rekening ini.', code: '42501'));

    final error = await provider.createTransaksi(
        kasAkunId: 2, jenis: 'masuk', kategori: 'Donasi', tanggal: DateTime(2026, 11, 1), nominal: 1);

    expect(error, 'Anda tidak memiliki izin mencatat transaksi pada rekening ini.');
  });

  test('a new account validates name and opening balance before calling the server', () async {
    expect(await provider.createAkun(namaAkun: ' '), isNotNull);
    expect(await provider.createAkun(namaAkun: 'Kas', saldoAwal: -1), isNotNull);
    verifyNever(() => service.createKasAkun(any()));
  });

  test('missing kas functions explain that the migration has to run', () {
    expect(
      KasProvider.messageFor(const PostgrestException(message: 'not found', code: 'PGRST202')),
      contains('migration_kas_v1.sql'),
    );
  });
}

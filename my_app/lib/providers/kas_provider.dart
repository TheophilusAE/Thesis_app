import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../models/kas.dart';
import '../services/supabase_service.dart';

/// Kas Keuangan & Rekening Dompet Kas. Reads are filtered by RLS (an admin
/// only sees accounts granted to them); writes go through RPCs that check
/// the permission server-side. Editing/deleting is Super Admin only.
class KasProvider extends ChangeNotifier {
  KasProvider({SupabaseService? service}) : _service = service ?? SupabaseService();

  final SupabaseService _service;

  List<KasAkun> _akun = [];
  List<KasTransaksi> _transaksi = [];
  KasFilter _filter = KasFilter.none;
  bool _isLoading = false;
  String? _error;

  List<KasAkun> get akun => _akun;
  List<KasAkun> get akunAktif => _akun.where((a) => a.isAktif).toList();
  List<KasTransaksi> get transaksi => _transaksi;
  KasFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get error => _error;
  KasRingkasan get ringkasan => KasRingkasan.of(_transaksi);
  num get totalSaldo => _akun.fold<num>(0, (s, a) => s + a.saldo);

  String namaAkun(int id) {
    for (final a in _akun) {
      if (a.id == id) return a.namaAkun;
    }
    return 'Rekening #$id';
  }

  static String messageFor(Object e) {
    if (e is PostgrestException) {
      if (const {'22023', 'P0002', '42501'}.contains(e.code)) return e.message;
      if (e.code == 'PGRST202' || e.code == 'PGRST205' || e.code == '42P01') {
        return 'Fitur Kas belum aktif di server. Jalankan migration_kas_v1.sql.';
      }
      return e.message;
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  Future<void> loadAkun() async {
    try {
      _akun = (await _service.getKasSaldo()).map(KasAkun.fromJson).toList();
      _error = null;
    } catch (e) {
      _error = messageFor(e);
      debugPrint('KasProvider.loadAkun: $e');
    }
    notifyListeners();
  }

  Future<void> loadTransaksi([KasFilter? filter]) async {
    if (filter != null) _filter = filter;
    _isLoading = true;
    notifyListeners();
    try {
      _transaksi = (await _service.getKasTransaksi(
        akunId: _filter.akunId,
        jenis: _filter.jenis,
        kategori: _filter.kategori,
        from: _filter.from,
        to: _filter.to,
      ))
          .map(KasTransaksi.fromJson)
          .toList();
      _error = null;
    } catch (e) {
      _error = messageFor(e);
      debugPrint('KasProvider.loadTransaksi: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAll() async {
    await loadAkun();
    await loadTransaksi();
  }

  /// Returns null on success or an error message.
  Future<String?> createAkun({
    required String namaAkun,
    String? nomorRekening,
    String? atasNama,
    num saldoAwal = 0,
    String? keterangan,
  }) async {
    if (namaAkun.trim().isEmpty) return 'Nama rekening wajib diisi.';
    if (saldoAwal < 0) return 'Saldo awal tidak boleh negatif.';
    try {
      await _service.createKasAkun({
        'nama_akun': namaAkun.trim(),
        'nomor_rekening': nomorRekening,
        'atas_nama': atasNama,
        'saldo_awal': saldoAwal,
        'keterangan': keterangan,
      });
      await loadAkun();
      return null;
    } catch (e) {
      return messageFor(e);
    }
  }

  /// Returns null on success or an error message. Validation mirrors the
  /// `create_kas_transaksi` RPC so the user gets instant feedback.
  Future<String?> createTransaksi({
    required int kasAkunId,
    required String jenis,
    required String kategori,
    required DateTime tanggal,
    required num nominal,
    String? namaPembayarPenerima,
    String? keterangan,
  }) async {
    final error = validateTransaksi(jenis: jenis, kategori: kategori, tanggal: tanggal, nominal: nominal);
    if (error != null) return error;
    try {
      await _service.createKasTransaksi({
        'kas_akun_id': kasAkunId,
        'jenis': jenis,
        'kategori': kategori.trim(),
        'tanggal': _iso(tanggal),
        'nominal': nominal,
        'nama_pembayar_penerima': namaPembayarPenerima,
        'keterangan': keterangan,
      });
      await loadAll();
      return null;
    } catch (e) {
      return messageFor(e);
    }
  }

  static String? validateTransaksi({
    required String jenis,
    required String kategori,
    required DateTime tanggal,
    required num nominal,
    DateTime? today,
  }) {
    if (jenis != KasJenis.masuk && jenis != KasJenis.keluar) return 'Pilih jenis: masuk atau keluar.';
    if (kategori.trim().isEmpty) return 'Kategori wajib diisi.';
    if (nominal <= 0) return 'Nominal harus lebih dari 0.';
    final now = today ?? DateTime.now();
    final t = DateTime(now.year, now.month, now.day);
    if (DateTime(tanggal.year, tanggal.month, tanggal.day).isAfter(t)) {
      return 'Tanggal transaksi tidak boleh di masa depan.';
    }
    return null;
  }

  /// Super Admin only.
  Future<String?> updateTransaksi(KasTransaksi t, {
    required String kategori,
    required num nominal,
    required DateTime tanggal,
    String? namaPembayarPenerima,
    String? keterangan,
  }) async {
    final error = validateTransaksi(jenis: t.jenis, kategori: kategori, tanggal: tanggal, nominal: nominal);
    if (error != null) return error;
    try {
      await _service.updateKasTransaksi(t.id, {
        'kategori': kategori.trim(),
        'nominal': nominal,
        'tanggal': _iso(tanggal),
        'nama_pembayar_penerima': namaPembayarPenerima,
        'keterangan': keterangan,
      });
      await loadAll();
      return null;
    } catch (e) {
      return messageFor(e);
    }
  }

  /// Super Admin only.
  Future<String?> deleteTransaksi(KasTransaksi t) async {
    try {
      await _service.deleteKasTransaksi(t.id);
      await loadAll();
      return null;
    } catch (e) {
      return messageFor(e);
    }
  }

  /// Super Admin only: activate / deactivate an account.
  Future<String?> setAkunAktif(KasAkun a, bool aktif) async {
    try {
      await _service.updateKasAkun(a.id, {'is_aktif': aktif});
      await loadAkun();
      return null;
    } catch (e) {
      return messageFor(e);
    }
  }

  Future<List<KasAkunAccess>> loadAccess(int akunId) async {
    final rows = await _service.getKasAkunAccess(akunId);
    return rows.map(KasAkunAccess.fromJson).toList();
  }

  /// Super Admin only. Returns null on success or an error message.
  Future<String?> setAccess({
    required int akunId,
    required String userId,
    required bool canRead,
    required bool canCreate,
  }) async {
    try {
      await _service.setKasAkunAccess(
          akunId: akunId, userId: userId, canRead: canRead, canCreate: canCreate);
      return null;
    } catch (e) {
      return messageFor(e);
    }
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

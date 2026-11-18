/// Church cash ledger (Kas Keuangan) on the existing `kas_*` tables, which
/// are shared with another system. Ids are bigint there.
library;

num _num(dynamic v) => v == null ? 0 : (v is num ? v : num.tryParse(v.toString()) ?? 0);

/// A cash wallet / bank account (Rekening Dompet Kas) with its balance,
/// read from `kas_saldo_view`.
class KasAkun {
  final int id;
  final String namaAkun;
  final String? nomorRekening;
  final String? atasNama;
  final bool isAktif;
  final num saldoAwal;
  final num totalMasuk;
  final num totalKeluar;
  final num saldo;

  const KasAkun({
    required this.id,
    required this.namaAkun,
    this.nomorRekening,
    this.atasNama,
    this.isAktif = true,
    this.saldoAwal = 0,
    this.totalMasuk = 0,
    this.totalKeluar = 0,
    this.saldo = 0,
  });

  factory KasAkun.fromJson(Map<String, dynamic> json) => KasAkun(
        id: _num(json['id']).toInt(),
        namaAkun: (json['nama_akun'] ?? '') as String,
        nomorRekening: json['nomor_rekening'] as String?,
        atasNama: json['atas_nama'] as String?,
        isAktif: (json['is_aktif'] ?? true) as bool,
        saldoAwal: _num(json['saldo_awal']),
        totalMasuk: _num(json['total_masuk']),
        totalKeluar: _num(json['total_keluar']),
        saldo: _num(json['saldo']),
      );
}

class KasJenis {
  KasJenis._();
  static const masuk = 'masuk';
  static const keluar = 'keluar';
}

/// Suggested categories (free text is allowed — the table has no lookup).
const List<String> kasKategoriSaran = [
  'Persembahan',
  'Perpuluhan',
  'Persembahan Khusus',
  'Donasi',
  'Operasional',
  'Pelayanan',
  'Diakonia',
  'Pembangunan',
  'Lain-lain',
];

class KasTransaksi {
  final int id;
  final String kodeTransaksi;
  final int kasAkunId;
  final String jenis;
  final String kategori;
  final DateTime tanggal;
  final num nominal;
  final String? namaPembayarPenerima;
  final String? keterangan;
  final String? dicatatOleh;

  const KasTransaksi({
    required this.id,
    required this.kodeTransaksi,
    required this.kasAkunId,
    required this.jenis,
    required this.kategori,
    required this.tanggal,
    required this.nominal,
    this.namaPembayarPenerima,
    this.keterangan,
    this.dicatatOleh,
  });

  bool get isMasuk => jenis == KasJenis.masuk;

  factory KasTransaksi.fromJson(Map<String, dynamic> json) {
    final d = DateTime.parse(json['tanggal'] as String);
    return KasTransaksi(
      id: _num(json['id']).toInt(),
      kodeTransaksi: (json['kode_transaksi'] ?? '') as String,
      kasAkunId: _num(json['kas_akun_id']).toInt(),
      jenis: (json['jenis'] ?? '') as String,
      kategori: (json['kategori'] ?? '') as String,
      tanggal: DateTime(d.year, d.month, d.day),
      nominal: _num(json['nominal']),
      namaPembayarPenerima: json['nama_pembayar_penerima'] as String?,
      keterangan: json['keterangan'] as String?,
      dicatatOleh: json['dicatat_oleh'] as String?,
    );
  }
}

/// Simple filter for the transaction list.
class KasFilter {
  final int? akunId;
  final String? jenis;
  final String? kategori;
  final DateTime? from;
  final DateTime? to;

  const KasFilter({this.akunId, this.jenis, this.kategori, this.from, this.to});

  static const none = KasFilter();

  bool get isEmpty =>
      akunId == null && jenis == null && (kategori?.isEmpty ?? true) && from == null && to == null;

  KasFilter copyWith({
    int? akunId,
    String? jenis,
    String? kategori,
    DateTime? from,
    DateTime? to,
    bool clearAkun = false,
    bool clearJenis = false,
    bool clearDates = false,
  }) =>
      KasFilter(
        akunId: clearAkun ? null : (akunId ?? this.akunId),
        jenis: clearJenis ? null : (jenis ?? this.jenis),
        kategori: kategori ?? this.kategori,
        from: clearDates ? null : (from ?? this.from),
        to: clearDates ? null : (to ?? this.to),
      );
}

/// Totals of a list of transactions (pure; shown above the filtered list).
class KasRingkasan {
  final num masuk;
  final num keluar;
  const KasRingkasan(this.masuk, this.keluar);
  num get selisih => masuk - keluar;

  static KasRingkasan of(Iterable<KasTransaksi> items) {
    num m = 0, k = 0;
    for (final t in items) {
      if (t.isMasuk) {
        m += t.nominal;
      } else {
        k += t.nominal;
      }
    }
    return KasRingkasan(m, k);
  }
}

/// One admin's access to one account (kas_akun_users row).
class KasAkunAccess {
  final String userId;
  final String userName;
  final String userEmail;
  final bool canRead;
  final bool canCreate;

  const KasAkunAccess({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.canRead,
    required this.canCreate,
  });

  factory KasAkunAccess.fromJson(Map<String, dynamic> json) {
    final u = json['users'];
    return KasAkunAccess(
      userId: json['user_id'] as String,
      userName: u is Map ? (u['nama'] as String? ?? '') : '',
      userEmail: u is Map ? (u['email'] as String? ?? '') : '',
      canRead: (json['can_read'] ?? false) as bool,
      canCreate: (json['can_create'] ?? false) as bool,
    );
  }
}

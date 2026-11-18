/// Worship schedule v2: a recurring series with a stable id, materialized as
/// one occurrence per date (see migration_scheduling_v2.sql).
library;

/// Kinds of worship the client named; free text is stored, so new kinds
/// can be typed in too.
const List<String> ibadahJenisOptions = [
  'Ibadah Umum',
  'Ibadah Raya Minggu',
  'Ibadah Pemuda',
  'Ibadah Sekolah Minggu',
  'Ibadah Tengah Minggu',
  'Doa Syafaat',
  'Event Khusus',
];

/// Recurrence values stored in `ibadah_series.pola` (same constants as
/// `utils/recurrence.dart`, plus NONE for a single date).
const String polaNone = 'NONE';

DateTime _date(String s) {
  final d = DateTime.parse(s);
  return DateTime(d.year, d.month, d.day);
}

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class IbadahSeries {
  final String id;
  final String nama;
  final String jenis;
  final String? categoryId;
  final String deskripsi;
  final String lokasi;
  final String? youtubeUrl;
  final String pola;
  final DateTime startDate;
  final DateTime? endDate;
  final String startTime;
  final String endTime;
  final bool isActive;

  const IbadahSeries({
    required this.id,
    required this.nama,
    required this.jenis,
    this.categoryId,
    this.deskripsi = '',
    this.lokasi = '',
    this.youtubeUrl,
    this.pola = polaNone,
    required this.startDate,
    this.endDate,
    required this.startTime,
    this.endTime = '',
    this.isActive = true,
  });

  bool get isRecurring => pola != polaNone;

  factory IbadahSeries.fromJson(Map<String, dynamic> json) => IbadahSeries(
        id: json['id'] as String,
        nama: (json['nama'] ?? '') as String,
        jenis: (json['jenis'] ?? '') as String,
        categoryId: json['category_id'] as String?,
        deskripsi: (json['deskripsi'] ?? '') as String,
        lokasi: (json['lokasi'] ?? '') as String,
        youtubeUrl: json['youtube_url'] as String?,
        pola: (json['pola'] ?? polaNone) as String,
        startDate: _date(json['start_date'] as String),
        endDate: json['end_date'] == null ? null : _date(json['end_date'] as String),
        startTime: (json['start_time'] ?? '') as String,
        endTime: (json['end_time'] ?? '') as String,
        isActive: (json['is_active'] ?? true) as bool,
      );

  /// Payload for the `create_ibadah_series` RPC.
  Map<String, dynamic> toCreateJson() => {
        'nama': nama,
        'jenis': jenis,
        'category_id': categoryId,
        'deskripsi': deskripsi,
        'lokasi': lokasi,
        'youtube_url': youtubeUrl,
        'pola': pola,
        'start_date': isoDate(startDate),
        'end_date': endDate == null ? null : isoDate(endDate!),
        'start_time': startTime,
        'end_time': endTime,
      };
}

/// One worship date, read from `ibadah_schedule_view` (effective values:
/// the occurrence override or the series value).
class IbadahOccurrence {
  final String id;
  final String seriesId;
  final DateTime tanggal;
  final String startTime;
  final String endTime;
  final String lokasi;
  final String deskripsi;
  final String? youtubeUrl;
  final String status;
  final String nama;
  final String jenis;
  final String? categoryId;
  final String pola;

  const IbadahOccurrence({
    required this.id,
    required this.seriesId,
    required this.tanggal,
    required this.startTime,
    this.endTime = '',
    this.lokasi = '',
    this.deskripsi = '',
    this.youtubeUrl,
    this.status = 'scheduled',
    required this.nama,
    required this.jenis,
    this.categoryId,
    this.pola = polaNone,
  });

  bool get isCancelled => status == 'cancelled';
  bool get hasLive => youtubeUrl != null && youtubeUrl!.trim().isNotEmpty;

  String get timeLabel => endTime.isEmpty ? startTime : '$startTime – $endTime';

  factory IbadahOccurrence.fromJson(Map<String, dynamic> json) => IbadahOccurrence(
        id: (json['occurrence_id'] ?? json['id']) as String,
        seriesId: (json['series_id'] ?? '') as String,
        tanggal: _date(json['tanggal'] as String),
        startTime: (json['start_time'] ?? '') as String,
        endTime: (json['end_time'] ?? '') as String,
        lokasi: (json['lokasi'] ?? '') as String,
        deskripsi: (json['deskripsi'] ?? '') as String,
        youtubeUrl: json['youtube_url'] as String?,
        status: (json['status'] ?? 'scheduled') as String,
        nama: (json['nama'] ?? '') as String,
        jenis: (json['jenis'] ?? '') as String,
        categoryId: json['category_id'] as String?,
        pola: (json['pola'] ?? polaNone) as String,
      );
}

/// One public worship service slot shown to guests and members: type,
/// name, date, time, place and live link — never the pelayan on duty
/// (see `get_public_service_schedule`).
class PublicServiceSlot {
  final String? occurrenceId;
  final String serviceType;
  final String nama;
  final DateTime date; // calendar date (no time component)
  final String startTime;
  final String endTime;
  final String lokasi;
  final String? youtubeUrl;

  const PublicServiceSlot({
    this.occurrenceId,
    required this.serviceType,
    String? nama,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.lokasi = '',
    this.youtubeUrl,
  }) : nama = nama ?? serviceType;

  factory PublicServiceSlot.fromJson(Map<String, dynamic> json) {
    final raw = (json['service_date'] ?? '') as String;
    final parsed = DateTime.parse(raw);
    final type = (json['service_type'] ?? '') as String;
    return PublicServiceSlot(
      occurrenceId: json['occurrence_id'] as String?,
      serviceType: type,
      nama: (json['nama'] as String?) ?? type,
      date: DateTime(parsed.year, parsed.month, parsed.day),
      startTime: (json['start_time'] ?? '') as String,
      endTime: (json['end_time'] ?? '') as String,
      lokasi: (json['lokasi'] as String?) ?? '',
      youtubeUrl: json['youtube_url'] as String?,
    );
  }

  bool get hasLive => youtubeUrl != null && youtubeUrl!.trim().isNotEmpty;

  /// Title to show: the series name, or the type when they're the same.
  String get title => nama.isEmpty ? serviceType : nama;

  String get timeLabel =>
      endTime.isEmpty ? startTime : '$startTime – $endTime';

  /// Groups slots by calendar date (ascending), each day sorted by start time.
  static List<MapEntry<DateTime, List<PublicServiceSlot>>> groupByDate(
      List<PublicServiceSlot> slots) {
    final map = <DateTime, List<PublicServiceSlot>>{};
    for (final s in slots) {
      map.putIfAbsent(s.date, () => []).add(s);
    }
    final days = map.keys.toList()..sort();
    return [
      for (final d in days)
        MapEntry(d, map[d]!..sort((a, b) => a.startTime.compareTo(b.startTime))),
    ];
  }
}

/// One public worship service slot shown to guests: type, date and time
/// only — never the pelayan on duty (see `get_public_service_schedule`).
class PublicServiceSlot {
  final String serviceType;
  final DateTime date; // calendar date (no time component)
  final String startTime;
  final String endTime;

  const PublicServiceSlot({
    required this.serviceType,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  factory PublicServiceSlot.fromJson(Map<String, dynamic> json) {
    final raw = (json['service_date'] ?? '') as String;
    final parsed = DateTime.parse(raw);
    return PublicServiceSlot(
      serviceType: (json['service_type'] ?? '') as String,
      date: DateTime(parsed.year, parsed.month, parsed.day),
      startTime: (json['start_time'] ?? '') as String,
      endTime: (json['end_time'] ?? '') as String,
    );
  }

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

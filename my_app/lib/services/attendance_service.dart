import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AttendanceService {
  static const _eventsKey = 'attendance_events';
  static const _recordsKey = 'attendance_records';

  Future<List<Map<String, dynamic>>> getEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_eventsKey);
    if (raw == null || raw.isEmpty) {
      return [
        {
          'id': 'evt-ibadah-minggu',
          'name': 'Ibadah Minggu',
          'date': DateTime.now().toIso8601String(),
          'mode': 'option1',
        },
      ];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveEvents(List<Map<String, dynamic>> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_eventsKey, jsonEncode(events));
  }

  Future<Map<String, dynamic>> createEvent({
    required String name,
    required String mode,
  }) async {
    final events = await getEvents();
    final event = {
      'id': 'evt-${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'date': DateTime.now().toIso8601String(),
      'mode': mode,
    };
    events.add(event);
    await saveEvents(events);
    return event;
  }

  Future<List<Map<String, dynamic>>> getAttendanceRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recordsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> markAttendance({
    required String eventId,
    required String eventName,
    required String memberId,
    required String memberName,
    required String source,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getAttendanceRecords();

    final alreadyExists = records.any(
      (record) =>
          record['eventId'] == eventId && record['memberId'] == memberId,
    );
    if (alreadyExists) {
      return;
    }

    records.add({
      'id': 'att-${DateTime.now().microsecondsSinceEpoch}',
      'eventId': eventId,
      'eventName': eventName,
      'memberId': memberId,
      'memberName': memberName,
      'source': source,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await prefs.setString(_recordsKey, jsonEncode(records));
  }
}

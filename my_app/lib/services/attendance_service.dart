import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class EventQrPayload {
  final String eventId;
  final String eventName;

  const EventQrPayload({
    required this.eventId,
    required this.eventName,
  });
}

class MemberQrPayload {
  final String memberId;
  final String memberName;

  const MemberQrPayload({
    required this.memberId,
    required this.memberName,
  });
}

class AttendanceService {
  static const _eventsKey = 'attendance_events';
  static const _recordsKey = 'attendance_records';

  static Map<String, String>? _parseStructuredPayload(String raw) {
    final segments = raw
        .split('|')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();

    if (segments.isEmpty) {
      return null;
    }

    final payload = <String, String>{'TYPE': segments.first};
    for (final segment in segments.skip(1)) {
      final separatorIndex = segment.indexOf(':');
      if (separatorIndex <= 0 || separatorIndex == segment.length - 1) {
        continue;
      }

      final key = segment.substring(0, separatorIndex).trim().toUpperCase();
      final value = segment.substring(separatorIndex + 1).trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        payload[key] = value;
      }
    }

    return payload;
  }

  EventQrPayload? parseEventQr(String raw) {
    final payload = _parseStructuredPayload(raw);
    if (payload == null || payload['TYPE'] != 'CHURCH_EVENT') {
      return null;
    }

    final eventId = payload['EID'];
    final eventName = payload['EVENT'];
    if (eventId == null || eventName == null) {
      return null;
    }

    return EventQrPayload(eventId: eventId, eventName: eventName);
  }

  MemberQrPayload? parseMemberQr(String raw) {
    final payload = _parseStructuredPayload(raw);
    if (payload != null && payload['TYPE'] == 'CHURCH_MEMBER') {
      final memberId = payload['UID'];
      final memberName = payload['NAME'];
      if (memberId == null || memberName == null) {
        return null;
      }

      return MemberQrPayload(memberId: memberId, memberName: memberName);
    }

    // Backward compatibility: member card QR may still contain plain member ID only.
    final fallbackId = raw.trim();
    if (fallbackId.isEmpty) {
      return null;
    }

    return MemberQrPayload(memberId: fallbackId, memberName: 'Jemaat');
  }

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

  Future<bool> markAttendance({
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
      return false;
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
    return true;
  }
}

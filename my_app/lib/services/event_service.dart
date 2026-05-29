import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event.dart';
import '../models/event_registration.dart';

class EventService {
  static final _db = Supabase.instance.client;

  // ── Events ────────────────────────────────────────────────

  Future<List<ChurchEvent>> getActiveEvents() async {
    try {
      final data = await _db
          .from('church_events')
          .select()
          .eq('is_active', true)
          .order('date');
      return (data as List)
          .map((e) => ChurchEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getActiveEvents error: $e');
      return [];
    }
  }

  Future<List<ChurchEvent>> getAllEvents() async {
    try {
      final data = await _db
          .from('church_events')
          .select()
          .order('date', ascending: false);
      return (data as List)
          .map((e) => ChurchEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getAllEvents error: $e');
      return [];
    }
  }

  Future<bool> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String location,
    int? maxCapacity,
  }) async {
    try {
      await _db.from('church_events').insert({
        'title': title,
        'description': description,
        'date': date.toUtc().toIso8601String(),
        'location': location,
        'max_capacity': maxCapacity,
        'is_active': true,
      });
      return true;
    } catch (e) {
      debugPrint('createEvent error: $e');
      return false;
    }
  }

  Future<bool> updateEvent(ChurchEvent event) async {
    try {
      await _db
          .from('church_events')
          .update(event.toJson())
          .eq('id', event.id);
      return true;
    } catch (e) {
      debugPrint('updateEvent error: $e');
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      await _db.from('church_events').delete().eq('id', eventId);
      return true;
    } catch (e) {
      debugPrint('deleteEvent error: $e');
      return false;
    }
  }

  Future<bool> toggleActive(String eventId, {required bool isActive}) async {
    try {
      await _db
          .from('church_events')
          .update({'is_active': isActive})
          .eq('id', eventId);
      return true;
    } catch (e) {
      debugPrint('toggleActive error: $e');
      return false;
    }
  }

  // ── Registrations ─────────────────────────────────────────

  Future<EventRegistration?> getUserRegistration(
      String eventId, String userId) async {
    try {
      final data = await _db
          .from('event_registrations')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return null;
      return EventRegistration.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('getUserRegistration error: $e');
      return null;
    }
  }

  Future<bool> registerForEvent({
    required String eventId,
    required String userId,
    required List<FamilyMember> familyMembers,
    String? notes,
  }) async {
    try {
      await _db.from('event_registrations').upsert({
        'event_id': eventId,
        'user_id': userId,
        'family_members':
            familyMembers.map((m) => m.toJson()).toList(),
        'total_count': 1 + familyMembers.length,
        'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      });
      return true;
    } catch (e) {
      debugPrint('registerForEvent error: $e');
      return false;
    }
  }

  Future<bool> cancelRegistration(String eventId, String userId) async {
    try {
      await _db
          .from('event_registrations')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('cancelRegistration error: $e');
      return false;
    }
  }

  /// Returns total attendees (sum of total_count) already registered for event.
  Future<int> getRegisteredCount(String eventId) async {
    try {
      final data = await _db
          .from('event_registrations')
          .select('total_count')
          .eq('event_id', eventId);
      return (data as List).fold<int>(
          0, (sum, e) => sum + ((e['total_count'] as int?) ?? 1));
    } catch (e) {
      debugPrint('getRegisteredCount error: $e');
      return 0;
    }
  }

  /// Admin: get all registrations for an event with user info.
  Future<List<EventRegistration>> getEventRegistrations(
      String eventId) async {
    try {
      final data = await _db
          .from('event_registrations')
          .select('*, users(name, email)')
          .eq('event_id', eventId)
          .order('registered_at');
      return (data as List)
          .map((e) =>
              EventRegistration.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getEventRegistrations error: $e');
      return [];
    }
  }
}

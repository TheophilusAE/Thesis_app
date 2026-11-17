import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event.dart';
import '../models/event_registration.dart';
import '../utils/event_capacity.dart';

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

  /// The user's registration for an event. `event_registrations` has no
  /// unique key on (event_id, user_id), and older app versions could create
  /// duplicates, so this reads the earliest row instead of `maybeSingle()`
  /// (which throws when more than one row exists).
  Future<EventRegistration?> getUserRegistration(
      String eventId, String userId) async {
    try {
      final data = await _db
          .from('event_registrations')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .order('registered_at')
          .limit(1);
      final rows = data as List;
      if (rows.isEmpty) return null;
      return EventRegistration.fromJson(rows.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('getUserRegistration error: $e');
      return null;
    }
  }

  /// Registers (or updates the existing registration of) [userId].
  /// Returns null on success, or a user-facing error message.
  ///
  /// Capacity is re-checked against a fresh headcount right before writing.
  /// See `utils/event_capacity.dart` for why this is best-effort only.
  Future<String?> registerForEvent({
    required String eventId,
    required String userId,
    required List<FamilyMember> familyMembers,
    int? maxCapacity,
    String? notes,
  }) async {
    final total = 1 + familyMembers.length;
    final cleanNotes = notes?.trim().isEmpty == true ? null : notes?.trim();
    try {
      final existing = await getUserRegistration(eventId, userId);

      if (maxCapacity != null) {
        final current = await getRegisteredCountOrNull(eventId);
        if (current == null) {
          return 'Tidak dapat memeriksa kuota acara. Periksa koneksi lalu coba lagi.';
        }
        if (!fitsCapacity(
          maxCapacity: maxCapacity,
          currentCount: current,
          requestedTotal: total,
          existingTotal: existing?.totalCount ?? 0,
        )) {
          final left = remainingCapacity(
            maxCapacity: maxCapacity,
            currentCount: current,
            existingTotal: existing?.totalCount ?? 0,
          );
          return 'Kuota tidak mencukupi. Sisa kuota: ${left ?? 0} orang.';
        }
      }

      final fields = {
        'family_members': familyMembers.map((m) => m.toJson()).toList(),
        'total_count': total,
        'notes': cleanNotes,
      };
      if (existing != null) {
        // Update by primary key and never rewrite event_id/user_id, so an
        // edit can't move or reassign the registration row.
        await _db.from('event_registrations').update(fields).eq('id', existing.id);
      } else {
        await _db.from('event_registrations').insert({
          'event_id': eventId,
          'user_id': userId,
          ...fields,
        });
      }
      return null;
    } catch (e) {
      debugPrint('registerForEvent error: $e');
      return 'Pendaftaran gagal disimpan. Periksa koneksi lalu coba lagi.';
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

  /// Returns total attendees (sum of total_count) already registered for
  /// event. Goes through a SECURITY DEFINER RPC so every jemaat can see
  /// the aggregate capacity count even though row-level access to other
  /// users' registrations is restricted.
  Future<int> getRegisteredCount(String eventId) async {
    return await getRegisteredCountOrNull(eventId) ?? 0;
  }

  /// Like [getRegisteredCount] but returns null on failure, so a capacity
  /// check never mistakes "couldn't load" for "nobody registered yet".
  Future<int?> getRegisteredCountOrNull(String eventId) async {
    try {
      final result = await _db.rpc(
        'get_event_registration_count',
        params: {'p_event_id': eventId},
      );
      return (result as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('getRegisteredCount error: $e');
      return null;
    }
  }

  /// Admin: get all registrations for an event with user info.
  Future<List<EventRegistration>> getEventRegistrations(
      String eventId) async {
    try {
      final data = await _db
          .from('event_registrations')
          .select('*, users(nama, email)')
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

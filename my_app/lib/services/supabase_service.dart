import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Postgrest sometimes hands back a result whose static/runtime list type
  // doesn't satisfy `List<Map<String, dynamic>>` directly (each element IS
  // a Map, but the wrapping List's type doesn't unify), which throws a
  // "List<dynamic> is not a subtype of List<Map<String, dynamic>>" cast
  // error at the `return` boundary of an `async` function with a strict
  // return type. Funneling every list result through this helper avoids
  // that — this was previously silently breaking almost every screen that
  // reads from Supabase (admin user list, schedules, attendance,
  // notifications, feedback, pelayans, substitution requests, bible...).
  static List<Map<String, dynamic>> _asMapList(dynamic data) {
    return List<Map<String, dynamic>>.from(
      (data as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  // ============== AUTH ==============
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nama,
    required String phone,
    Map<String, dynamic>? additionalData,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'nama': nama, 'phone': phone},
    );
    if (response.user != null) {
      // upsert handles both: trigger already created profile OR profile doesn't exist yet
      final profileData = <String, dynamic>{
        'id': response.user!.id,
        'email': email,
        'nama': nama,
        'phone': phone,
        'roles': ['jemaat'],
        'membership_status': 'pending',
        if (additionalData != null) ...additionalData,
      };
      try {
        await _client.from('users').upsert(profileData);
      } catch (e) {
        // User record creation is non-fatal — user can still log in
        debugPrint('User upsert warning (non-fatal): $e');
      }
    }
    return response;
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async => await _client.auth.signOut();

  User? getCurrentUser() => _client.auth.currentUser;

  Stream<AuthState> onAuthStateChange() => _client.auth.onAuthStateChange;

  // ============== USERS ==============
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final data = await _client.from('users').select().eq('id', userId).single();
      return Map<String, dynamic>.from(data);
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _client.from('users').update(data).eq('id', userId);
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final data = await _client.from('users').select().order('nama');
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    final data = await _client
        .from('users')
        .select()
        .eq('membership_status', 'pending')
        .order('nama');
    return _asMapList(data);
  }

  Future<void> verifyUser(String userId, {required bool approved}) async {
    await _client.from('users').update({
      'membership_status': approved ? 'active' : 'rejected',
    }).eq('id', userId);
  }

  Future<void> updateUserRoles(String userId, List<String> roles) async {
    await _client.from('users').update({'roles': roles}).eq('id', userId);
  }

  Future<void> deleteUserProfile(String userId) async {
    await _client.from('users').delete().eq('id', userId);
  }

  // ============== PELAYANS ==============
  Future<List<Map<String, dynamic>>> getPelayans() async {
    final data = await _client.from('pelayans').select().order('nama');
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getActivePelayans() async {
    final data = await _client.from('pelayans').select().eq('is_aktif', true).order('nama');
    return _asMapList(data);
  }

  Future<Map<String, dynamic>> addPelayan(Map<String, dynamic> data) async {
    final response = await _client.from('pelayans').insert(data).select();
    return Map<String, dynamic>.from(_asMapList(response).first);
  }

  Future<void> updatePelayan(String id, Map<String, dynamic> data) async {
    await _client.from('pelayans').update(data).eq('id', id);
  }

  Future<void> deletePelayan(String id) async {
    await _client.from('pelayans').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> searchPelayans(String query) async {
    final data = await _client.from('pelayans').select().ilike('nama', '%$query%').order('nama');
    return _asMapList(data);
  }

  // ============== SERVICE SCHEDULES ==============
  Future<List<Map<String, dynamic>>> getSchedules() async {
    final data = await _client.from('schedules').select().order('service_date');
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getSchedulesByPelayan(String pelayananId) async {
    final data = await _client
        .from('schedules')
        .select()
        .eq('pelayan_id', pelayananId)
        .order('service_date');
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getUpcomingSchedulesByPelayan(String pelayananId) async {
    final now = DateTime.now().toIso8601String();
    final data = await _client
        .from('schedules')
        .select()
        .eq('pelayan_id', pelayananId)
        .gte('service_date', now)
        .order('service_date');
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getSchedulesByDateRange(
      DateTime start, DateTime end) async {
    final data = await _client
        .from('schedules')
        .select()
        .gte('service_date', start.toIso8601String())
        .lte('service_date', end.toIso8601String())
        .order('service_date');
    return _asMapList(data);
  }

  Future<Map<String, dynamic>> addSchedule(Map<String, dynamic> data) async {
    final response = await _client.from('schedules').insert(data).select();
    return Map<String, dynamic>.from(_asMapList(response).first);
  }

  Future<void> updateSchedule(String id, Map<String, dynamic> data) async {
    await _client.from('schedules').update(data).eq('id', id);
  }

  Future<void> deleteSchedule(String id) async {
    await _client.from('schedules').delete().eq('id', id);
  }

  // ============== TRAINING SCHEDULES ==============
  Future<List<Map<String, dynamic>>> getTrainingSchedules() async {
    final data = await _client.from('training_schedules').select().order('training_date');
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getTrainingSchedulesForPelayan(String pelayananId) async {
    final data = await _client
        .from('training_schedules')
        .select()
        .contains('pelayan_ids', [pelayananId])
        .order('training_date');
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getUpcomingTrainingSchedules(String pelayananId) async {
    final now = DateTime.now().toIso8601String();
    final data = await _client
        .from('training_schedules')
        .select()
        .contains('pelayan_ids', [pelayananId])
        .gte('training_date', now)
        .order('training_date');
    return _asMapList(data);
  }

  Future<Map<String, dynamic>> addTrainingSchedule(Map<String, dynamic> data) async {
    final response = await _client.from('training_schedules').insert(data).select();
    return Map<String, dynamic>.from(_asMapList(response).first);
  }

  Future<void> updateTrainingSchedule(String id, Map<String, dynamic> data) async {
    await _client.from('training_schedules').update(data).eq('id', id);
  }

  Future<void> deleteTrainingSchedule(String id) async {
    await _client.from('training_schedules').delete().eq('id', id);
  }

  // ============== SUBSTITUTION REQUESTS ==============
  Future<List<Map<String, dynamic>>> getSubstitutionRequests() async {
    final data = await _client
        .from('substitution_requests')
        .select()
        .order('created_at', ascending: false);
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getPendingSubstitutionRequests() async {
    final data = await _client
        .from('substitution_requests')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getSubstitutionRequestsByUser(String userId) async {
    final data = await _client
        .from('substitution_requests')
        .select()
        .eq('requested_by_user_id', userId)
        .order('created_at', ascending: false);
    return _asMapList(data);
  }

  Future<Map<String, dynamic>> addSubstitutionRequest(Map<String, dynamic> data) async {
    final response = await _client.from('substitution_requests').insert(data).select();
    return Map<String, dynamic>.from(_asMapList(response).first);
  }

  Future<void> updateSubstitutionRequest(String id, Map<String, dynamic> data) async {
    await _client.from('substitution_requests').update(data).eq('id', id);
  }

  Future<void> deleteSubstitutionRequest(String id) async {
    await _client.from('substitution_requests').delete().eq('id', id);
  }

  // ============== ATTENDANCE ==============
  Future<List<Map<String, dynamic>>> getAllAttendance() async {
    final data = await _client.from('attendance').select().order('schedule_date', ascending: false);
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getAttendanceByUser(String userId) async {
    final data = await _client
        .from('attendance')
        .select()
        .eq('user_id', userId)
        .order('schedule_date', ascending: false);
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getAttendanceBySchedule(String scheduleId) async {
    final data = await _client
        .from('attendance')
        .select()
        .eq('service_schedule_id', scheduleId)
        .order('schedule_date');
    return _asMapList(data);
  }

  Future<Map<String, dynamic>?> getAttendanceByUserAndSchedule(
      String userId, String scheduleId) async {
    try {
      final result = await _client
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .eq('service_schedule_id', scheduleId)
          .maybeSingle();
      return result == null ? null : Map<String, dynamic>.from(result);
    } catch (e) {
      debugPrint('Error fetching attendance: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> upsertAttendance(Map<String, dynamic> data) async {
    final response = await _client
        .from('attendance')
        .upsert(data, onConflict: 'user_id,service_schedule_id')
        .select();
    return Map<String, dynamic>.from(_asMapList(response).first);
  }

  Future<void> updateAttendance(String id, Map<String, dynamic> data) async {
    await _client.from('attendance').update(data).eq('id', id);
  }

  Future<void> deleteAttendance(String id) async {
    await _client.from('attendance').delete().eq('id', id);
  }

  // ============== NOTIFICATIONS ==============
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return _asMapList(data);
  }

  Future<Map<String, dynamic>> addNotification(Map<String, dynamic> data) async {
    final response = await _client.from('notifications').insert(data).select();
    return Map<String, dynamic>.from(_asMapList(response).first);
  }

  Future<void> markNotificationAsRead(String id) async {
    await _client.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    await _client.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId).eq('is_read', false);
  }

  Future<void> deleteNotification(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }

  Future<void> deleteAllNotifications(String userId) async {
    await _client.from('notifications').delete().eq('user_id', userId);
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final result = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false);
    return _asMapList(result).length;
  }

  // ============== FEEDBACK ==============
  Future<List<Map<String, dynamic>>> getAllFeedback() async {
    final data = await _client.from('feedback').select().order('created_at', ascending: false);
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getFeedbackByUser(String userId) async {
    final data = await _client
        .from('feedback')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getFeedbackByType(String feedbackType) async {
    final data = await _client
        .from('feedback')
        .select()
        .eq('feedback_type', feedbackType)
        .order('created_at', ascending: false);
    return _asMapList(data);
  }

  Future<Map<String, dynamic>> addFeedback(Map<String, dynamic> data) async {
    final response = await _client.from('feedback').insert(data).select();
    return Map<String, dynamic>.from(_asMapList(response).first);
  }

  Future<void> deleteFeedback(String id) async {
    await _client.from('feedback').delete().eq('id', id);
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> resendConfirmationEmail(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  // ============== PRAYER REQUESTS ==============
  Future<List<Map<String, dynamic>>> getMyPrayerRequests(String userId) async {
    final data = await _client
        .from('prayer_requests')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getAllPrayerRequests() async {
    final data =
        await _client.from('prayer_requests').select().order('created_at', ascending: false);
    return _asMapList(data);
  }

  Future<Map<String, dynamic>> addPrayerRequest(Map<String, dynamic> data) async {
    final response = await _client.from('prayer_requests').insert(data).select();
    return Map<String, dynamic>.from(_asMapList(response).first);
  }

  Future<void> updatePrayerRequest(String id, Map<String, dynamic> data) async {
    await _client.from('prayer_requests').update(data).eq('id', id);
  }

  Future<void> deletePrayerRequest(String id) async {
    await _client.from('prayer_requests').delete().eq('id', id);
  }

  // ============== KOMSEL (SMALL GROUPS) ==============
  Future<List<Map<String, dynamic>>> getKomsels() async {
    final data = await _client.from('komsels').select().order('nama');
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getActiveKomsels() async {
    final data = await _client.from('komsels').select().eq('is_active', true).order('nama');
    return _asMapList(data);
  }

  Future<Map<String, dynamic>> addKomsel(Map<String, dynamic> data) async {
    final response = await _client.from('komsels').insert(data).select();
    return Map<String, dynamic>.from(_asMapList(response).first);
  }

  Future<void> updateKomsel(String id, Map<String, dynamic> data) async {
    await _client.from('komsels').update(data).eq('id', id);
  }

  Future<void> deleteKomsel(String id) async {
    await _client.from('komsels').delete().eq('id', id);
  }

  // ============== SERMONS / MEDIA LIBRARY ==============
  Future<List<Map<String, dynamic>>> getSermons() async {
    final data = await _client.from('sermons').select().order('sermon_date', ascending: false);
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getActiveSermons() async {
    final data = await _client
        .from('sermons')
        .select()
        .eq('is_active', true)
        .order('sermon_date', ascending: false);
    return _asMapList(data);
  }

  Future<Map<String, dynamic>> addSermon(Map<String, dynamic> data) async {
    final response = await _client.from('sermons').insert(data).select();
    return Map<String, dynamic>.from(_asMapList(response).first);
  }

  Future<void> updateSermon(String id, Map<String, dynamic> data) async {
    await _client.from('sermons').update(data).eq('id', id);
  }

  Future<void> deleteSermon(String id) async {
    await _client.from('sermons').delete().eq('id', id);
  }

  // ============== BIBLE ==============
  Future<List<Map<String, dynamic>>> getBibleVerses(String book, int chapter) async {
    final data = await _client
        .from('bible_verses')
        .select()
        .eq('book', book)
        .eq('chapter', chapter)
        .order('verse');
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> searchBibleVerses(String query) async {
    final data = await _client
        .from('bible_verses')
        .select()
        .or('text.ilike.%$query%,book.ilike.%$query%')
        .limit(50);
    return _asMapList(data);
  }

  // ============== REAL-TIME ==============
  RealtimeChannel subscribeToSchedules(void Function(dynamic) onEvent) {
    final channel = _client.channel('public:schedules');
    channel
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(event: '*', schema: 'public', table: 'schedules'),
          (payload, [ref]) => onEvent(payload),
        )
        .subscribe();
    return channel;
  }

  RealtimeChannel subscribeToNotifications(
      String userId, void Function(dynamic) onEvent) {
    final channel = _client.channel('public:notifications:$userId');
    channel
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: '*',
            schema: 'public',
            table: 'notifications',
            filter: 'user_id=eq.$userId',
          ),
          (payload, [ref]) => onEvent(payload),
        )
        .subscribe();
    return channel;
  }

  RealtimeChannel subscribeToAttendance(void Function(dynamic) onEvent) {
    final channel = _client.channel('public:attendance');
    channel
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(event: '*', schema: 'public', table: 'attendance'),
          (payload, [ref]) => onEvent(payload),
        )
        .subscribe();
    return channel;
  }

  void unsubscribeChannel(RealtimeChannel channel) {
    _client.removeChannel(channel);
  }
}

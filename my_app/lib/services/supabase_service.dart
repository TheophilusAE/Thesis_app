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

  /// Approve/reject/deactivate a member through the `set_member_status` RPC,
  /// which checks the caller's `users:approve` permission (Super Admin for
  /// 'inactive'/'pending'). Direct UPDATEs of membership_status are blocked
  /// by a database trigger for everyone except Super Admin.
  Future<void> setMemberStatus(String userId, String status) async {
    await _client.rpc('set_member_status', params: {
      'p_user_id': userId,
      'p_status': status,
    });
  }

  /// Roles can only be changed by a Super Admin (enforced by RLS + trigger).
  /// `.select()` makes a silently-blocked update visible as an error.
  Future<void> updateUserRoles(String userId, List<String> roles) async {
    final rows = await _client
        .from('users')
        .update({'roles': roles, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', userId)
        .select('id');
    if ((rows as List).isEmpty) {
      throw Exception('Perubahan role ditolak: hanya Super Admin yang dapat mengubah role.');
    }
  }

  /// Fills in a freshly created account (admin "Tambah Pengguna" flow) via
  /// the `admin_complete_new_user` RPC — Admin only needs `users:create`.
  Future<void> adminCompleteNewUser({
    required String userId,
    required List<String> roles,
    required String status,
    required Map<String, dynamic> profile,
  }) async {
    await _client.rpc('admin_complete_new_user', params: {
      'p_user_id': userId,
      'p_roles': roles,
      'p_status': status,
      'p_profile': profile,
    });
  }

  // ============== RBAC: ADMIN PERMISSIONS ==============

  /// True when PostgREST reports a missing table/function, i.e. the RBAC v2
  /// migration has not been run on this database yet.
  static bool isMissingRelation(Object e) {
    if (e is PostgrestException) {
      final code = e.code ?? '';
      return code == '42P01' || code == 'PGRST205' || code == 'PGRST202' || code == '42883';
    }
    final msg = e.toString();
    return msg.contains('42P01') || msg.contains('PGRST205');
  }

  /// The signed-in admin's own grants. Returns null when the
  /// `admin_permissions` table does not exist yet (pre-migration database).
  Future<List<Map<String, dynamic>>?> getMyAdminPermissions(String userId) async {
    try {
      final data = await _client.from('admin_permissions').select().eq('user_id', userId);
      return _asMapList(data);
    } catch (e) {
      if (isMissingRelation(e)) return null;
      rethrow;
    }
  }

  /// All grants (Super Admin only — RLS returns only your own rows otherwise).
  Future<List<Map<String, dynamic>>> getAllAdminPermissions() async {
    final data = await _client.from('admin_permissions').select();
    return _asMapList(data);
  }

  /// Replaces every grant of [userId] atomically (`set_admin_permissions`).
  Future<void> setAdminPermissions(String userId, List<Map<String, dynamic>> grants) async {
    await _client.rpc('set_admin_permissions', params: {
      'p_user_id': userId,
      'p_grants': grants,
    });
  }

  Future<List<Map<String, dynamic>>> getAdminCategories() async {
    final data = await _client.from('admin_categories').select().order('nama');
    return _asMapList(data);
  }

  Future<void> addAdminCategory({required String kode, required String nama}) async {
    await _client.from('admin_categories').insert({'kode': kode, 'nama': nama});
  }

  Future<void> setAdminCategoryActive(String id, bool isActive) async {
    await _client.from('admin_categories').update({
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ============== PUBLIC (GUEST) DATA ==============

  /// Service schedule without pelayan names, readable by guests (anon).
  Future<List<Map<String, dynamic>>> getPublicServiceSchedule(DateTime from, DateTime to) async {
    String day(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final data = await _client.rpc('get_public_service_schedule', params: {
      'p_from': day(from),
      'p_to': day(to),
    });
    return _asMapList(data);
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

  /// Atomic review (`review_substitution` RPC): on approval the duty is moved
  /// to [replacementPelayanId] and the request is marked approved in one
  /// transaction. Requires `jadwal_pelayanan:approve`. Returns the RPC's JSON
  /// result (status, replacement_user_id, replacement_name, ...).
  Future<Map<String, dynamic>> reviewSubstitution({
    required String requestId,
    required bool approve,
    String? replacementPelayanId,
    String? adminNotes,
  }) async {
    final result = await _client.rpc('review_substitution', params: {
      'p_request_id': requestId,
      'p_approve': approve,
      'p_replacement_pelayan_id': replacementPelayanId,
      'p_admin_notes': adminNotes,
    });
    return result is Map ? Map<String, dynamic>.from(result) : <String, dynamic>{};
  }

  /// The requester cancels their own pending request.
  Future<void> cancelSubstitutionRequest(String requestId) async {
    await _client.rpc('cancel_substitution_request', params: {'p_request_id': requestId});
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

  /// Inserts notifications addressed to other users (admin broadcast).
  /// Deliberately no `.select()`: `notif_select_own` only lets a user read
  /// their own rows, so asking for the inserted rows back would make the
  /// RETURNING clause fail RLS even though the insert itself is allowed.
  Future<void> addNotifications(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client.from('notifications').insert(rows);
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

  /// Status change by an admin with `prayer:approve` (RPC-checked).
  Future<void> updatePrayerStatus(String id, String status) async {
    await _client.rpc('update_prayer_status', params: {'p_id': id, 'p_status': status});
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

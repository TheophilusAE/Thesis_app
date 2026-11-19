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

  // ============== JADWAL IBADAH v2 (series + occurrence) ==============

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Worship dates in [from, to] with effective values (view).
  Future<List<Map<String, dynamic>>> getIbadahOccurrences(DateTime from, DateTime to) async {
    final data = await _client
        .from('ibadah_schedule_view')
        .select()
        .gte('tanggal', _isoDate(from))
        .lte('tanggal', _isoDate(to))
        .order('tanggal')
        .order('start_time');
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getIbadahSeries() async {
    final data = await _client.from('ibadah_series').select().order('nama');
    return _asMapList(data);
  }

  /// Creates a series and its dates atomically; returns the series id.
  Future<String> createIbadahSeries(Map<String, dynamic> series, List<DateTime> dates) async {
    final id = await _client.rpc('create_ibadah_series', params: {
      'p_series': series,
      'p_dates': dates.map(_isoDate).toList(),
    });
    return id as String;
  }

  /// Adds missing future dates of a recurring series (rolling horizon).
  Future<int> ensureIbadahOccurrences(String seriesId, List<DateTime> dates) async {
    final n = await _client.rpc('ensure_ibadah_occurrences', params: {
      'p_series_id': seriesId,
      'p_dates': dates.map(_isoDate).toList(),
    });
    return (n as num?)?.toInt() ?? 0;
  }

  /// Super Admin: edit a series (past dates keep their old values).
  Future<void> updateIbadahSeries(String seriesId, Map<String, dynamic> changes) async {
    await _client.rpc('update_ibadah_series', params: {
      'p_series_id': seriesId,
      'p_changes': changes,
    });
  }

  /// Super Admin: change one date (cancel, or override place/time/live link).
  Future<void> updateIbadahOccurrence(String occurrenceId, Map<String, dynamic> data) async {
    final rows = await _client
        .from('ibadah_occurrences')
        .update({...data, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', occurrenceId)
        .select('id');
    if ((rows as List).isEmpty) {
      throw Exception('Perubahan ditolak: hanya Super Admin yang dapat mengubah tanggal ibadah.');
    }
  }

  // ============== CHECK-IN QR & MEMBER QR ==============

  /// Token for the check-in QR a pelayan/admin displays.
  Future<Map<String, dynamic>> issueCheckinToken(String targetType, String targetId) async {
    final r = await _client.rpc('issue_checkin_token', params: {
      'p_target_type': targetType,
      'p_target_id': targetId,
    });
    return Map<String, dynamic>.from(r as Map);
  }

  Future<String> getMyMemberQrSecret() async {
    final r = await _client.rpc('get_my_member_qr_secret');
    return r as String;
  }

  Future<Map<String, dynamic>> selfCheckIn(String targetType, String targetId, String token) async {
    final r = await _client.rpc('self_check_in', params: {
      'p_target_type': targetType,
      'p_target_id': targetId,
      'p_token': token,
    });
    return Map<String, dynamic>.from(r as Map);
  }

  Future<Map<String, dynamic>> staffCheckIn({
    required String targetType,
    required String targetId,
    required String userId,
    required String secret,
  }) async {
    final r = await _client.rpc('staff_check_in', params: {
      'p_target_type': targetType,
      'p_target_id': targetId,
      'p_user_id': userId,
      'p_secret': secret,
    });
    return Map<String, dynamic>.from(r as Map);
  }

  // ============== KAS KEUANGAN & REKENING ==============

  /// Accounts with balance; RLS limits admins to accounts they may read.
  Future<List<Map<String, dynamic>>> getKasSaldo() async {
    final data = await _client.from('kas_saldo_view').select().order('nama_akun');
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getKasTransaksi({
    int? akunId,
    String? jenis,
    String? kategori,
    DateTime? from,
    DateTime? to,
    int limit = 500,
  }) async {
    var q = _client.from('kas_transaksis').select();
    if (akunId != null) q = q.eq('kas_akun_id', akunId);
    if (jenis != null) q = q.eq('jenis', jenis);
    if (kategori != null && kategori.isNotEmpty) q = q.ilike('kategori', '%$kategori%');
    if (from != null) q = q.gte('tanggal', _isoDate(from));
    if (to != null) q = q.lte('tanggal', _isoDate(to));
    final data = await q.order('tanggal', ascending: false).order('id', ascending: false).limit(limit);
    return _asMapList(data);
  }

  Future<int> createKasAkun(Map<String, dynamic> data) async {
    final id = await _client.rpc('create_kas_akun', params: {'p_data': data});
    return (id as num).toInt();
  }

  Future<Map<String, dynamic>> createKasTransaksi(Map<String, dynamic> data) async {
    final r = await _client.rpc('create_kas_transaksi', params: {'p_data': data});
    return Map<String, dynamic>.from(r as Map);
  }

  // ── Push (migration_push_fcm.sql) ──

  /// Links this phone's FCM token to the signed-in user (RPC moves a token
  /// that was registered by another account on the same phone).
  Future<void> saveDeviceToken(String token, {required String platform}) async {
    await _client.rpc('register_device_token', params: {'p_token': token, 'p_platform': platform});
  }

  Future<void> deleteDeviceToken(String token) async {
    await _client.from('device_tokens').delete().eq('token', token);
  }

  // ── Hapus akun (migration_account_deletion.sql + Edge Function delete-account) ──

  /// Permanently deletes the signed-in user's own account. The Edge Function
  /// identifies the caller from their JWT and holds the service key; throws
  /// [AccountDeletionException] with a user-facing message on failure.
  Future<void> deleteMyAccount() async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw const AccountDeletionException('Sesi tidak valid. Silakan login ulang.');
    final FunctionResponse res;
    try {
      res = await _client.functions
          .invoke('delete-account', headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 30));
    } on FormatException {
      throw const AccountDeletionException('Layanan hapus akun belum aktif. Hubungi admin gereja.');
    }
    final status = res.status ?? 0;
    if (status >= 200 && status < 300) return;
    final data = res.data;
    final msg = data is Map && data['error'] is String
        ? data['error'] as String
        : status == 404
            ? 'Layanan hapus akun belum aktif. Hubungi admin gereja.'
            : 'Gagal menghapus akun (kode $status). Coba lagi nanti.';
    throw AccountDeletionException(msg);
  }

  // ── Pengumuman & ucapan (migration_notifications_v2.sql) ──

  /// Announcements, newest first. RLS: active ones for approved members,
  /// all for admins with notifikasi:read.
  Future<List<Map<String, dynamic>>> getBroadcasts({bool activeOnly = true, int limit = 50}) async {
    var q = _client.from('notification_broadcasts').select();
    if (activeOnly) q = q.eq('is_active', true);
    final rows = await q.order('created_at', ascending: false).limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Creates an announcement and delivers it to the audience's inboxes.
  Future<Map<String, dynamic>> createBroadcast(Map<String, dynamic> data) async {
    final r = await _client.rpc('create_broadcast', params: {'p': data});
    return Map<String, dynamic>.from(r as Map);
  }

  /// Super Admin: edits an announcement (also in recipients' inboxes).
  Future<void> updateBroadcast(String id, Map<String, dynamic> changes) async {
    await _client.rpc('update_broadcast', params: {'p_id': id, 'p': changes});
  }

  /// Super Admin: deletes notifications older than [days] (≥ 30). Returns the count.
  Future<int> purgeOldNotifications(int days) async {
    final r = await _client.rpc('purge_old_notifications', params: {'p_older_than_days': days});
    return (r as num).toInt();
  }

  Future<List<Map<String, dynamic>>> getBirthdaysToday() async {
    final r = await _client.rpc('birthdays_today');
    return List<Map<String, dynamic>>.from(r as List);
  }

  /// Sends the birthday greeting to everyone not yet greeted today.
  Future<Map<String, dynamic>> sendBirthdayGreetings() async {
    final r = await _client.rpc('send_birthday_greetings');
    return Map<String, dynamic>.from(r as Map);
  }

  /// Super Admin only (RLS). Throws when the change was refused.
  Future<void> updateKasAkun(int id, Map<String, dynamic> data) async {
    final rows = await _client.from('kas_akuns').update(data).eq('id', id).select('id');
    if ((rows as List).isEmpty) throw Exception('Perubahan rekening ditolak (khusus Super Admin).');
  }

  Future<void> updateKasTransaksi(int id, Map<String, dynamic> data) async {
    final rows = await _client.from('kas_transaksis').update(data).eq('id', id).select('id');
    if ((rows as List).isEmpty) throw Exception('Perubahan transaksi ditolak (khusus Super Admin).');
  }

  Future<void> deleteKasTransaksi(int id) async {
    final rows = await _client.from('kas_transaksis').delete().eq('id', id).select('id');
    if ((rows as List).isEmpty) throw Exception('Penghapusan transaksi ditolak (khusus Super Admin).');
  }

  Future<List<Map<String, dynamic>>> getKasAkunAccess(int akunId) async {
    final data = await _client
        .from('kas_akun_users')
        .select('*, users(nama, email)')
        .eq('kas_akun_id', akunId);
    return _asMapList(data);
  }

  Future<void> setKasAkunAccess({
    required int akunId,
    required String userId,
    required bool canRead,
    required bool canCreate,
  }) async {
    await _client.rpc('set_kas_akun_access', params: {
      'p_akun_id': akunId,
      'p_user_id': userId,
      'p_can_read': canRead,
      'p_can_create': canCreate,
    });
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

  // ============== GROUP (tabel komsels) ==============
  Future<List<Map<String, dynamic>>> getGroups() async {
    final data = await _client.from('komsels').select().order('nama');
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> getActiveGroups() async {
    final data = await _client.from('komsels').select().eq('is_active', true).order('nama');
    return _asMapList(data);
  }

  Future<Map<String, dynamic>> addGroup(Map<String, dynamic> data) async {
    final response = await _client.from('komsels').insert(data).select();
    return Map<String, dynamic>.from(_asMapList(response).first);
  }

  Future<void> updateGroup(String id, Map<String, dynamic> data) async {
    await _client.from('komsels').update(data).eq('id', id);
  }

  Future<void> deleteGroup(String id) async {
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

/// A user-facing reason why the account could not be deleted.
class AccountDeletionException implements Exception {
  final String message;
  const AccountDeletionException(this.message);
  @override
  String toString() => message;
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../services/supabase_service.dart';
import '../utils/qr_payload.dart';

/// Result of a check-in attempt (self-scan or staff scan).
class CheckinResult {
  final bool ok;
  /// 'checked_in' | 'already' on success.
  final String? status;
  final String? label; // worship/event name
  final String? memberName;
  final String? error;

  const CheckinResult._({required this.ok, this.status, this.label, this.memberName, this.error});

  factory CheckinResult.success(Map<String, dynamic> r) => CheckinResult._(
        ok: true,
        status: r['status'] as String?,
        label: r['label'] as String?,
        memberName: r['nama'] as String?,
      );

  factory CheckinResult.failure(String message) => CheckinResult._(ok: false, error: message);

  bool get alreadyCheckedIn => status == 'already';
}

/// A displayed check-in code: the QR data plus when it stops working.
class CheckinCode {
  final String qrData;
  final String label;
  final DateTime validUntil;

  const CheckinCode({required this.qrData, required this.label, required this.validUntil});
}

/// QR check-in flows. Every rule (token, time window, booking required,
/// one check-in per person, member card secret) is enforced by the
/// database RPCs; this class only calls them and words the outcome.
class CheckinProvider extends ChangeNotifier {
  CheckinProvider({SupabaseService? service}) : _service = service ?? SupabaseService();

  final SupabaseService _service;
  String? _memberSecret;
  String? _secretOwner;

  /// Database messages from our RPCs are written for users; anything else
  /// becomes a generic network message.
  static String messageFor(Object e) {
    if (e is PostgrestException) {
      if (const {'22023', 'P0002', '42501'}.contains(e.code)) return e.message;
      if (e.code == 'PGRST202' || e.code == '42883') {
        return 'Fitur check-in belum aktif di server. Hubungi admin.';
      }
    }
    final m = e.toString();
    if (m.contains('SocketException') || m.toLowerCase().contains('network')) {
      return 'Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.';
    }
    return 'Check-in gagal diproses. Coba lagi.';
  }

  /// QR data for the signed-in member's card (includes the card secret).
  Future<String> memberQrData({required String userId, required String name}) async {
    if (_memberSecret == null || _secretOwner != userId) {
      _memberSecret = await _service.getMyMemberQrSecret();
      _secretOwner = userId;
    }
    return encodeMemberPayload(userId: userId, name: name, secret: _memberSecret);
  }

  /// Forget the cached card secret (call on sign-out).
  void clear() {
    _memberSecret = null;
    _secretOwner = null;
  }

  /// Check-in QR for a pelayan/admin to display for one worship date/event.
  Future<CheckinCode> issueCode(String targetType, String targetId) async {
    final r = await _service.issueCheckinToken(targetType, targetId);
    return CheckinCode(
      qrData: encodeCheckinPayload(
          targetType: targetType, targetId: targetId, token: r['token'] as String),
      label: (r['label'] as String?) ?? '',
      validUntil: DateTime.parse(r['valid_until'] as String).toLocal(),
    );
  }

  /// A jemaat scanned a check-in code.
  Future<CheckinResult> selfCheckIn(String rawQr) async {
    if (isLegacyServicePayload(rawQr)) {
      return CheckinResult.failure(
          'QR ini model lama dan tidak berlaku lagi. Minta petugas menampilkan QR presensi terbaru.');
    }
    final p = decodeCheckinPayload(rawQr);
    if (p == null) {
      return CheckinResult.failure('Ini bukan QR presensi ibadah/event.');
    }
    try {
      return CheckinResult.success(await _service.selfCheckIn(p.targetType, p.targetId, p.token));
    } catch (e) {
      debugPrint('selfCheckIn: $e');
      return CheckinResult.failure(messageFor(e));
    }
  }

  /// A pelayan/admin scanned a member card for [targetType]/[targetId].
  Future<CheckinResult> staffCheckIn({
    required String targetType,
    required String targetId,
    required String rawQr,
  }) async {
    final member = decodeMemberPayload(rawQr);
    if (member == null) {
      return CheckinResult.failure('Ini bukan QR kartu jemaat.');
    }
    if (member.isLegacy) {
      return CheckinResult.failure(
          'QR kartu jemaat ini model lama. Minta jemaat membuka ulang "QR Jemaat Saya" di aplikasi.');
    }
    try {
      return CheckinResult.success(await _service.staffCheckIn(
        targetType: targetType,
        targetId: targetId,
        userId: member.userId,
        secret: member.secret!,
      ));
    } catch (e) {
      debugPrint('staffCheckIn: $e');
      return CheckinResult.failure(messageFor(e));
    }
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/substitution_request.dart';

class SubstitutionRequestService {
  static const String _substitutionKey = '_substitutionRequestKey';
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Add new substitution request
  Future<SubstitutionRequest> addSubstitutionRequest(
    SubstitutionRequest request,
  ) async {
    final id = const Uuid().v4();
    final newRequest = request.copyWith(
      id: id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final allRequests = await getAllSubstitutionRequests();
    allRequests.add(newRequest);

    await _saveRequests(allRequests);
    return newRequest;
  }

  /// Get all substitution requests
  Future<List<SubstitutionRequest>> getAllSubstitutionRequests() async {
    final jsonString = _prefs.getString(_substitutionKey) ?? '[]';
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((json) => SubstitutionRequest.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get pending requests (for admin review)
  Future<List<SubstitutionRequest>> getPendingRequests() async {
    final all = await getAllSubstitutionRequests();
    return all.where((r) => r.status == 'pending').toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get requests for a specific user
  Future<List<SubstitutionRequest>> getRequestsByUser(String userId) async {
    final all = await getAllSubstitutionRequests();
    return all.where((r) => r.requestedByUserId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get requests for a specific service schedule
  Future<List<SubstitutionRequest>> getRequestsBySchedule(
    String scheduleId,
  ) async {
    final all = await getAllSubstitutionRequests();
    return all.where((r) => r.serviceScheduleId == scheduleId).toList();
  }

  /// Update request status
  Future<bool> updateRequestStatus({
    required String requestId,
    required String status,
    String? adminNotes,
    String? replacementUserId,
    String? replacementName,
  }) async {
    final allRequests = await getAllSubstitutionRequests();
    final index = allRequests.indexWhere((r) => r.id == requestId);

    if (index == -1) return false;

    final updated = allRequests[index].copyWith(
      status: status,
      adminNotes: adminNotes,
      replacementUserId: replacementUserId,
      replacementName: replacementName,
      updatedAt: DateTime.now(),
      reviewedAt: DateTime.now(),
    );

    allRequests[index] = updated;
    await _saveRequests(allRequests);
    return true;
  }

  /// Approve substitution request
  Future<bool> approveSubstitutionRequest({
    required String requestId,
    required String replacementUserId,
    required String replacementName,
    String? adminNotes,
  }) async {
    return updateRequestStatus(
      requestId: requestId,
      status: 'approved',
      adminNotes: adminNotes,
      replacementUserId: replacementUserId,
      replacementName: replacementName,
    );
  }

  /// Reject substitution request
  Future<bool> rejectSubstitutionRequest({
    required String requestId,
    String? adminNotes,
  }) async {
    return updateRequestStatus(
      requestId: requestId,
      status: 'rejected',
      adminNotes: adminNotes,
    );
  }

  /// Delete substitution request
  Future<bool> deleteSubstitutionRequest(String requestId) async {
    final allRequests = await getAllSubstitutionRequests();
    final initialLength = allRequests.length;
    allRequests.removeWhere((r) => r.id == requestId);

    if (allRequests.length < initialLength) {
      await _saveRequests(allRequests);
      return true;
    }
    return false;
  }

  /// Save requests to storage
  Future<void> _saveRequests(List<SubstitutionRequest> requests) async {
    final jsonList = requests.map((r) => r.toJson()).toList();
    await _prefs.setString(_substitutionKey, jsonEncode(jsonList));
  }

  /// Get count of pending requests
  Future<int> getPendingRequestCount() async {
    final pending = await getPendingRequests();
    return pending.length;
  }

  /// Search requests by user name
  Future<List<SubstitutionRequest>> searchRequests(String query) async {
    if (query.isEmpty) {
      return getAllSubstitutionRequests();
    }

    final all = await getAllSubstitutionRequests();
    final lowerQuery = query.toLowerCase();

    return all.where((r) {
      return r.requestedByName.toLowerCase().contains(lowerQuery) ||
          r.reason.toLowerCase().contains(lowerQuery) ||
          r.status.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}

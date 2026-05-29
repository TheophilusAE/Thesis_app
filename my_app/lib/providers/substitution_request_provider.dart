import 'package:flutter/material.dart';
import '../models/substitution_request.dart';
import '../services/supabase_service.dart';

class SubstitutionRequestProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<SubstitutionRequest> _allRequests = [];
  List<SubstitutionRequest> _filteredRequests = [];
  List<SubstitutionRequest> _pendingRequests = [];
  List<SubstitutionRequest> _userRequests = [];
  bool _isLoading = false;
  String? _error;
  int _pendingCount = 0;

  List<SubstitutionRequest> get allRequests => _allRequests;
  List<SubstitutionRequest> get filteredRequests => _filteredRequests;
  List<SubstitutionRequest> get pendingRequests => _pendingRequests;
  List<SubstitutionRequest> get userRequests => _userRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get pendingCount => _pendingCount;

  Future<void> loadAllRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getSubstitutionRequests();
      _allRequests = data.map((e) => SubstitutionRequest.fromJson(e)).toList();
      _filteredRequests = List.from(_allRequests);
      _pendingRequests = _allRequests.where((r) => r.status == 'pending').toList();
      _pendingCount = _pendingRequests.length;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading substitution requests: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPendingRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getPendingSubstitutionRequests();
      _pendingRequests = data.map((e) => SubstitutionRequest.fromJson(e)).toList();
      _pendingCount = _pendingRequests.length;
      _filteredRequests = List.from(_pendingRequests);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading pending requests: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUserRequests(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getSubstitutionRequestsByUser(userId);
      _userRequests = data.map((e) => SubstitutionRequest.fromJson(e)).toList();
      _filteredRequests = List.from(_userRequests);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading user requests: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createSubstitutionRequest(SubstitutionRequest request) async {
    try {
      final result = await _service.addSubstitutionRequest(request.toSupabaseJson());
      final created = SubstitutionRequest.fromJson(result);
      _allRequests.insert(0, created);
      _userRequests.insert(0, created);
      _filteredRequests = List.from(_userRequests);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating substitution request: $e');
      return false;
    }
  }

  Future<bool> approveRequest({
    required String requestId,
    required String replacementUserId,
    required String replacementName,
    String? adminNotes,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _service.updateSubstitutionRequest(requestId, {
        'status': 'approved',
        'replacement_user_id': replacementUserId,
        'replacement_name': replacementName,
        'admin_notes': adminNotes,
        'reviewed_at': now,
        'updated_at': now,
      });
      _updateLocalRequest(requestId, status: 'approved',
          replacementUserId: replacementUserId,
          replacementName: replacementName,
          adminNotes: adminNotes);
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error approving request: $e');
      return false;
    }
  }

  Future<bool> rejectRequest({required String requestId, String? adminNotes}) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _service.updateSubstitutionRequest(requestId, {
        'status': 'rejected',
        'admin_notes': adminNotes,
        'reviewed_at': now,
        'updated_at': now,
      });
      _updateLocalRequest(requestId, status: 'rejected', adminNotes: adminNotes);
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error rejecting request: $e');
      return false;
    }
  }

  Future<bool> cancelRequest(String requestId) async {
    try {
      await _service.updateSubstitutionRequest(requestId, {
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      });
      _updateLocalRequest(requestId, status: 'cancelled');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error cancelling request: $e');
      return false;
    }
  }

  Future<void> filterByStatus(String status) async {
    if (status.isEmpty) {
      _filteredRequests = List.from(_allRequests);
    } else {
      _filteredRequests = _allRequests.where((r) => r.status == status).toList();
    }
    notifyListeners();
  }

  void _updateLocalRequest(
    String requestId, {
    String? status,
    String? replacementUserId,
    String? replacementName,
    String? adminNotes,
  }) {
    void updateInList(List<SubstitutionRequest> list) {
      final idx = list.indexWhere((r) => r.id == requestId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(
          status: status,
          replacementUserId: replacementUserId,
          replacementName: replacementName,
          adminNotes: adminNotes,
          updatedAt: DateTime.now(),
          reviewedAt: DateTime.now(),
        );
      }
    }

    updateInList(_allRequests);
    updateInList(_userRequests);
    updateInList(_pendingRequests);
    _pendingRequests = _allRequests.where((r) => r.status == 'pending').toList();
    _pendingCount = _pendingRequests.length;
    _filteredRequests = List.from(_allRequests);
    notifyListeners();
  }
}

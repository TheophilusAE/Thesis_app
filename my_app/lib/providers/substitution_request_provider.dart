import 'package:flutter/material.dart';
import '../models/substitution_request.dart';
import '../services/substitution_request_service.dart';

class SubstitutionRequestProvider extends ChangeNotifier {
  final SubstitutionRequestService _service;

  List<SubstitutionRequest> _allRequests = [];
  List<SubstitutionRequest> _filteredRequests = [];
  List<SubstitutionRequest> _pendingRequests = [];
  List<SubstitutionRequest> _userRequests = [];
  bool _isLoading = false;
  int _pendingCount = 0;

  SubstitutionRequestProvider({
    required SubstitutionRequestService service,
  }) : _service = service;

  // Getters
  List<SubstitutionRequest> get allRequests => _allRequests;
  List<SubstitutionRequest> get filteredRequests => _filteredRequests;
  List<SubstitutionRequest> get pendingRequests => _pendingRequests;
  List<SubstitutionRequest> get userRequests => _userRequests;
  bool get isLoading => _isLoading;
  int get pendingCount => _pendingCount;

  /// Load all substitution requests
  Future<void> loadAllRequests() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allRequests = await _service.getAllSubstitutionRequests();
      _filteredRequests = _allRequests;
      _pendingCount = _allRequests.where((r) => r.status == 'pending').length;
    } catch (e) {
      debugPrint('Error loading substitution requests: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load pending requests
  Future<void> loadPendingRequests() async {
    _isLoading = true;
    notifyListeners();

    try {
      _pendingRequests = await _service.getPendingRequests();
      _pendingCount = _pendingRequests.length;
    } catch (e) {
      debugPrint('Error loading pending requests: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load requests for specific user
  Future<void> loadUserRequests(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userRequests = await _service.getRequestsByUser(userId);
    } catch (e) {
      debugPrint('Error loading user substitution requests: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create new substitution request
  Future<bool> createSubstitutionRequest(SubstitutionRequest request) async {
    try {
      final newRequest = await _service.addSubstitutionRequest(request);
      _allRequests.insert(0, newRequest);
      _userRequests.insert(0, newRequest);
      _filteredRequests = _allRequests;
      _pendingCount++;

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating substitution request: $e');
      return false;
    }
  }

  /// Approve substitution request
  Future<bool> approveRequest({
    required String requestId,
    required String replacementUserId,
    required String replacementName,
    String? adminNotes,
  }) async {
    try {
      final success = await _service.approveSubstitutionRequest(
        requestId: requestId,
        replacementUserId: replacementUserId,
        replacementName: replacementName,
        adminNotes: adminNotes,
      );

      if (success) {
        final index = _allRequests.indexWhere((r) => r.id == requestId);
        if (index != -1) {
          _allRequests[index] = _allRequests[index].copyWith(
            status: 'approved',
            replacementUserId: replacementUserId,
            replacementName: replacementName,
            adminNotes: adminNotes,
            updatedAt: DateTime.now(),
            reviewedAt: DateTime.now(),
          );
        }

        _pendingRequests.removeWhere((r) => r.id == requestId);
        _pendingCount = _pendingRequests.length;
        notifyListeners();
      }

      return success;
    } catch (e) {
      debugPrint('Error approving substitution request: $e');
      return false;
    }
  }

  /// Reject substitution request
  Future<bool> rejectRequest({
    required String requestId,
    String? adminNotes,
  }) async {
    try {
      final success = await _service.rejectSubstitutionRequest(
        requestId: requestId,
        adminNotes: adminNotes,
      );

      if (success) {
        final index = _allRequests.indexWhere((r) => r.id == requestId);
        if (index != -1) {
          _allRequests[index] = _allRequests[index].copyWith(
            status: 'rejected',
            adminNotes: adminNotes,
            updatedAt: DateTime.now(),
            reviewedAt: DateTime.now(),
          );
        }

        _pendingRequests.removeWhere((r) => r.id == requestId);
        _pendingCount = _pendingRequests.length;
        notifyListeners();
      }

      return success;
    } catch (e) {
      debugPrint('Error rejecting substitution request: $e');
      return false;
    }
  }

  /// Delete substitution request
  Future<bool> deleteRequest(String requestId) async {
    try {
      final success = await _service.deleteSubstitutionRequest(requestId);
      if (success) {
        _allRequests.removeWhere((r) => r.id == requestId);
        _pendingRequests.removeWhere((r) => r.id == requestId);
        _userRequests.removeWhere((r) => r.id == requestId);
        _filteredRequests = _allRequests;
        _pendingCount = _pendingRequests.length;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting substitution request: $e');
      return false;
    }
  }

  /// Filter requests by status
  void filterByStatus(String status) {
    if (status.isEmpty) {
      _filteredRequests = _allRequests;
    } else {
      _filteredRequests = _allRequests.where((r) => r.status == status).toList();
    }
    notifyListeners();
  }

  /// Search requests
  Future<void> searchRequests(String query) async {
    try {
      _filteredRequests = await _service.searchRequests(query);
      notifyListeners();
    } catch (e) {
      debugPrint('Error searching substitution requests: $e');
    }
  }

  /// Get pending count (for UI notifications)
  Future<int> getPendingCount() async {
    try {
      _pendingCount = await _service.getPendingRequestCount();
      notifyListeners();
      return _pendingCount;
    } catch (e) {
      debugPrint('Error getting pending count: $e');
      return 0;
    }
  }
}

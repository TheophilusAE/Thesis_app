import 'package:flutter/material.dart';
import '../models/prayer_request.dart';
import '../services/supabase_service.dart';

class PrayerRequestProvider extends ChangeNotifier {
  PrayerRequestProvider({SupabaseService? service}) : _service = service ?? SupabaseService();

  final SupabaseService _service;

  List<PrayerRequest> _myRequests = [];
  List<PrayerRequest> _allRequests = [];
  bool _isLoading = false;
  String? _error;

  List<PrayerRequest> get myRequests => _myRequests;
  List<PrayerRequest> get allRequests => _allRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMyRequests(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getMyPrayerRequests(userId);
      _myRequests = data.map((e) => PrayerRequest.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading my prayer requests: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getAllPrayerRequests();
      _allRequests = data.map((e) => PrayerRequest.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading all prayer requests: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitRequest({
    required String userId,
    required String userName,
    required String category,
    required String content,
    bool isAnonymous = false,
  }) async {
    try {
      final data = PrayerRequest(
        id: '',
        userId: userId,
        userName: userName,
        category: category,
        content: content,
        isAnonymous: isAnonymous,
        createdAt: DateTime.now(),
      ).toSupabaseJson();
      final result = await _service.addPrayerRequest(data);
      final created = PrayerRequest.fromJson(result);
      _myRequests.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error submitting prayer request: $e');
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      await _service.updatePrayerRequest(id, {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _patchLocal(id, status: status);
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating prayer request status: $e');
      return false;
    }
  }

  Future<bool> deleteRequest(String id) async {
    try {
      await _service.deletePrayerRequest(id);
      _myRequests.removeWhere((r) => r.id == id);
      _allRequests.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting prayer request: $e');
      return false;
    }
  }

  void _patchLocal(String id, {required String status}) {
    final myIdx = _myRequests.indexWhere((r) => r.id == id);
    if (myIdx != -1) {
      _myRequests[myIdx] = _myRequests[myIdx].copyWith(status: status, updatedAt: DateTime.now());
    }
    final allIdx = _allRequests.indexWhere((r) => r.id == id);
    if (allIdx != -1) {
      _allRequests[allIdx] = _allRequests[allIdx].copyWith(status: status, updatedAt: DateTime.now());
    }
    notifyListeners();
  }
}

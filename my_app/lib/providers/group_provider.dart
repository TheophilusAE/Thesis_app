import 'package:flutter/material.dart';
import '../models/admin_category.dart';
import '../models/church_group.dart';
import '../services/supabase_service.dart';

/// Church groups (formerly "Komsel"; table `komsels`).
class GroupProvider extends ChangeNotifier {
  GroupProvider({SupabaseService? service}) : _service = service ?? SupabaseService();

  final SupabaseService _service;

  List<ChurchGroup> _allGroups = [];
  List<ChurchGroup> _activeGroups = [];
  List<AdminCategory> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<ChurchGroup> get allGroups => _allGroups;
  List<ChurchGroup> get activeGroups => _activeGroups;
  /// Active group categories (Umum, Anak/Sekolah Minggu, Pemuda, …).
  List<AdminCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ChurchGroup? groupById(String? id) {
    if (id == null) return null;
    for (final g in [..._allGroups, ..._activeGroups]) {
      if (g.id == id) return g;
    }
    return null;
  }

  String categoryLabel(String? categoryId) {
    if (categoryId == null) return 'Tanpa kategori';
    for (final c in _categories) {
      if (c.id == categoryId) return groupCategoryLabel(c);
    }
    return 'Kategori lain';
  }

  /// Loads the categories a group can belong to. Missing table (before the
  /// RBAC migration) simply leaves the list empty.
  Future<void> loadCategories() async {
    try {
      _categories = (await _service.getAdminCategories())
          .map(AdminCategory.fromJson)
          .where((c) => c.isActive)
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('GroupProvider.loadCategories: $e');
    }
  }

  Future<void> loadAllGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getGroups();
      _allGroups = data.map((e) => ChurchGroup.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading group: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadActiveGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getActiveGroups();
      _activeGroups = data.map((e) => ChurchGroup.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading active group: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addGroup(ChurchGroup churchGroup) async {
    try {
      final result = await _service.addGroup(churchGroup.toSupabaseJson());
      _allGroups.insert(0, ChurchGroup.fromJson(result));
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding group: $e');
      return false;
    }
  }

  Future<bool> updateGroup(String id, ChurchGroup churchGroup) async {
    try {
      await _service.updateGroup(id, {
        ...churchGroup.toSupabaseJson(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      final idx = _allGroups.indexWhere((k) => k.id == id);
      if (idx != -1) {
        _allGroups[idx] = churchGroup.copyWith(id: id, updatedAt: DateTime.now());
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating group: $e');
      return false;
    }
  }

  Future<bool> deleteGroup(String id) async {
    try {
      await _service.deleteGroup(id);
      _allGroups.removeWhere((k) => k.id == id);
      _activeGroups.removeWhere((k) => k.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting group: $e');
      return false;
    }
  }
}

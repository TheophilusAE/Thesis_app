import 'package:flutter/material.dart';
import '../models/pelayan.dart';
import '../services/supabase_service.dart';

class PelayaniProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;

  List<Pelayan> _allPelayan = [];
  List<Pelayan> _filteredPelayan = [];
  bool _isLoading = false;
  String? _errorMessage;

  PelayaniProvider({SupabaseService? service})
      : _supabaseService = service ?? SupabaseService();

  // Getters
  List<Pelayan> get allPelayan => _allPelayan;
  List<Pelayan> get filteredPelayan => _filteredPelayan;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load all Pelayan from Supabase
  Future<void> loadAllPelayan() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _supabaseService.getPelayans();
      _allPelayan = data.map((e) => Pelayan.fromJson(e)).toList();
      _filteredPelayan = _allPelayan;
    } catch (e) {
      debugPrint('Error loading Pelayan: $e');
      _errorMessage = 'Gagal memuat daftar pelayan.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load active Pelayan from Supabase
  Future<void> loadActivePelayan() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _supabaseService.getActivePelayans();
      _filteredPelayan = data.map((e) => Pelayan.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading active Pelayan: $e');
      _errorMessage = 'Gagal memuat daftar pelayan.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// The Pelayan record linked to an app account via `pelayans.user_id`.
  /// Schedules reference `pelayans.id`, never `users.id`, so this is the
  /// only correct way to find "my" schedules for the logged-in user.
  Pelayan? pelayanForUser(String? userId) {
    if (userId == null || userId.isEmpty) return null;
    for (final p in _allPelayan) {
      if (p.userId == userId) return p;
    }
    return null;
  }

  /// Add new Pelayan to Supabase. [userId] is the linked account
  /// (`users.id`); pass null for a Pelayan without an app account.
  Future<bool> addPelayan({
    required String nama,
    required String noTelepon,
    required String posisi,
    String? userId,
    bool isAktif = true,
  }) async {
    try {
      await _supabaseService.addPelayan({
        'nama': nama,
        'no_telepon': noTelepon,
        'posisi': posisi,
        'is_aktif': isAktif,
        'user_id': (userId == null || userId.isEmpty) ? null : userId,
      });

      await loadAllPelayan();
      return true;
    } catch (e) {
      debugPrint('Error adding Pelayan: $e');
      return false;
    }
  }

  /// Update Pelayan in Supabase
  Future<bool> updatePelayan(
    String id, {
    String? nama,
    String? noTelepon,
    String? posisi,
    bool? isAktif,
    bool updateUserLink = false,
    String? userId,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (nama != null) updateData['nama'] = nama;
      if (noTelepon != null) updateData['no_telepon'] = noTelepon;
      if (posisi != null) updateData['posisi'] = posisi;
      if (isAktif != null) updateData['is_aktif'] = isAktif;
      if (updateUserLink) {
        updateData['user_id'] = (userId == null || userId.isEmpty) ? null : userId;
      }

      await _supabaseService.updatePelayan(id, updateData);

      int index = _allPelayan.indexWhere((p) => p.id == id);
      if (index != -1) {
        _allPelayan[index] = _allPelayan[index].copyWith(
          nama: nama,
          noTelepon: noTelepon,
          posisi: posisi,
          isAktif: isAktif,
          userId: updateUserLink ? (userId ?? '') : null,
        );
        _filteredPelayan = _allPelayan;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating Pelayan: $e');
      return false;
    }
  }

  /// Delete Pelayan from Supabase
  Future<bool> deletePelayan(String id) async {
    try {
      await _supabaseService.deletePelayan(id);
      _allPelayan.removeWhere((p) => p.id == id);
      _filteredPelayan = _allPelayan;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting Pelayan: $e');
      return false;
    }
  }

  /// Search Pelayan by name from Supabase
  Future<void> searchPelayan(String query) async {
    if (query.isEmpty) {
      _filteredPelayan = _allPelayan;
    } else {
      try {
        final data = await _supabaseService.searchPelayans(query);
        _filteredPelayan = data.map((e) => Pelayan.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Error searching Pelayan: $e');
      }
    }
    notifyListeners();
  }

  /// Filter Pelayan by posisi
  void filterByPosisi(String posisi) {
    if (posisi.isEmpty) {
      _filteredPelayan = _allPelayan;
    } else {
      _filteredPelayan = _allPelayan.where((p) => p.posisi.toLowerCase() == posisi.toLowerCase()).toList();
    }
    notifyListeners();
  }

  /// Get Pelayan count
  int getPelayaniCount() {
    return _allPelayan.length;
  }

  /// Get active Pelayan count
  int getActivePelayaniCount() {
    return _allPelayan.where((p) => p.isAktif).length;
  }
}

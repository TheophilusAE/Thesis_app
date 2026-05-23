import 'package:flutter/material.dart';
import '../models/pelayan.dart';
import '../services/pelayan_service.dart';

class PelayaniProvider extends ChangeNotifier {
  final PelayaniService _pelayaniService;

  List<Pelayan> _allPelayan = [];
  List<Pelayan> _filteredPelayan = [];
  bool _isLoading = false;

  PelayaniProvider({required PelayaniService pelayaniService}) : _pelayaniService = pelayaniService;

  // Getters
  List<Pelayan> get allPelayan => _allPelayan;
  List<Pelayan> get filteredPelayan => _filteredPelayan;
  bool get isLoading => _isLoading;

  /// Load all Pelayan
  Future<void> loadAllPelayan() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allPelayan = await _pelayaniService.getAllPelayan();
      _filteredPelayan = _allPelayan;
    } catch (e) {
      debugPrint('Error loading Pelayan: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load Pelayan by User ID
  Future<void> loadPelayaniByUserId(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _filteredPelayan = await _pelayaniService.getPelayaniByUserId(userId);
    } catch (e) {
      debugPrint('Error loading Pelayan by user: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load active Pelayan
  Future<void> loadActivePelayan() async {
    _isLoading = true;
    notifyListeners();

    try {
      _filteredPelayan = await _pelayaniService.getActivePelayan();
    } catch (e) {
      debugPrint('Error loading active Pelayan: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add new Pelayan
  Future<bool> addPelayan({
    required String userId,
    required String nama,
    required String noTelepon,
    required String posisi,
  }) async {
    try {
      final newPelayan = await _pelayaniService.addPelayan(
        userId: userId,
        nama: nama,
        noTelepon: noTelepon,
        posisi: posisi,
      );

      _allPelayan.add(newPelayan);
      _filteredPelayan = _allPelayan;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error adding Pelayan: $e');
      return false;
    }
  }

  /// Update Pelayan
  Future<bool> updatePelayan(
    String id, {
    String? nama,
    String? noTelepon,
    String? posisi,
    bool? isAktif,
  }) async {
    try {
      final updated = await _pelayaniService.updatePelayan(
        id,
        nama: nama,
        noTelepon: noTelepon,
        posisi: posisi,
        isAktif: isAktif,
      );

      if (updated != null) {
        int index = _allPelayan.indexWhere((p) => p.id == id);
        if (index != -1) {
          _allPelayan[index] = updated;
          _filteredPelayan = _allPelayan;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating Pelayan: $e');
      return false;
    }
  }

  /// Delete Pelayan
  Future<bool> deletePelayan(String id) async {
    try {
      final success = await _pelayaniService.deletePelayan(id);
      if (success) {
        _allPelayan.removeWhere((p) => p.id == id);
        _filteredPelayan = _allPelayan;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting Pelayan: $e');
      return false;
    }
  }

  /// Search Pelayan by name
  Future<void> searchPelayan(String query) async {
    if (query.isEmpty) {
      _filteredPelayan = _allPelayan;
    } else {
      try {
        _filteredPelayan = await _pelayaniService.searchPelayan(query);
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
  Future<int> getPelayaniCount() async {
    return await _pelayaniService.getPelayaniCount();
  }

  /// Get active Pelayan count
  Future<int> getActivePelayaniCount() async {
    return await _pelayaniService.getActivePelayaniCount();
  }
}

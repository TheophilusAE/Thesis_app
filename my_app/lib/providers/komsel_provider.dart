import 'package:flutter/material.dart';
import '../models/komsel.dart';
import '../services/supabase_service.dart';

class KomselProvider extends ChangeNotifier {
  KomselProvider({SupabaseService? service}) : _service = service ?? SupabaseService();

  final SupabaseService _service;

  List<Komsel> _allKomsel = [];
  List<Komsel> _activeKomsel = [];
  bool _isLoading = false;
  String? _error;

  List<Komsel> get allKomsel => _allKomsel;
  List<Komsel> get activeKomsel => _activeKomsel;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAllKomsel() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getKomsels();
      _allKomsel = data.map((e) => Komsel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading komsel: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadActiveKomsel() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getActiveKomsels();
      _activeKomsel = data.map((e) => Komsel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading active komsel: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addKomsel(Komsel komsel) async {
    try {
      final result = await _service.addKomsel(komsel.toSupabaseJson());
      _allKomsel.insert(0, Komsel.fromJson(result));
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding komsel: $e');
      return false;
    }
  }

  Future<bool> updateKomsel(String id, Komsel komsel) async {
    try {
      await _service.updateKomsel(id, {
        ...komsel.toSupabaseJson(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      final idx = _allKomsel.indexWhere((k) => k.id == id);
      if (idx != -1) {
        _allKomsel[idx] = komsel.copyWith(id: id, updatedAt: DateTime.now());
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating komsel: $e');
      return false;
    }
  }

  Future<bool> deleteKomsel(String id) async {
    try {
      await _service.deleteKomsel(id);
      _allKomsel.removeWhere((k) => k.id == id);
      _activeKomsel.removeWhere((k) => k.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting komsel: $e');
      return false;
    }
  }
}

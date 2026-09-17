import 'package:flutter/material.dart';
import '../models/sermon.dart';
import '../services/supabase_service.dart';

class SermonProvider extends ChangeNotifier {
  SermonProvider({SupabaseService? service}) : _service = service ?? SupabaseService();

  final SupabaseService _service;

  List<Sermon> _allSermons = [];
  List<Sermon> _activeSermons = [];
  bool _isLoading = false;
  String? _error;

  List<Sermon> get allSermons => _allSermons;
  List<Sermon> get activeSermons => _activeSermons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAllSermons() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getSermons();
      _allSermons = data.map((e) => Sermon.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading sermons: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadActiveSermons() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.getActiveSermons();
      _activeSermons = data.map((e) => Sermon.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading active sermons: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addSermon(Sermon sermon) async {
    try {
      final result = await _service.addSermon(sermon.toSupabaseJson());
      _allSermons.insert(0, Sermon.fromJson(result));
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding sermon: $e');
      return false;
    }
  }

  Future<bool> updateSermon(String id, Sermon sermon) async {
    try {
      await _service.updateSermon(id, {
        ...sermon.toSupabaseJson(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      final idx = _allSermons.indexWhere((s) => s.id == id);
      if (idx != -1) {
        _allSermons[idx] = sermon.copyWith(id: id, updatedAt: DateTime.now());
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating sermon: $e');
      return false;
    }
  }

  Future<bool> deleteSermon(String id) async {
    try {
      await _service.deleteSermon(id);
      _allSermons.removeWhere((s) => s.id == id);
      _activeSermons.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting sermon: $e');
      return false;
    }
  }
}

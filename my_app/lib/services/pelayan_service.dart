import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pelayan.dart';
import 'package:uuid/uuid.dart';

class PelayaniService {
  static const String _pelayaniKey = '_pelayaniKey';
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get all Pelayan
  Future<List<Pelayan>> getAllPelayan() async {
    final jsonString = _prefs.getString(_pelayaniKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((item) => Pelayan.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Get Pelayan by ID
  Future<Pelayan?> getPelayaniById(String id) async {
    final allPelayan = await getAllPelayan();
    try {
      return allPelayan.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get Pelayan by User ID
  Future<List<Pelayan>> getPelayaniByUserId(String userId) async {
    final allPelayan = await getAllPelayan();
    return allPelayan.where((p) => p.userId == userId).toList();
  }

  /// Add new Pelayan
  Future<Pelayan> addPelayan({
    required String userId,
    required String nama,
    required String noTelepon,
    required String posisi,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    final pelayan = Pelayan(
      id: id,
      userId: userId,
      nama: nama,
      noTelepon: noTelepon,
      posisi: posisi,
      isAktif: true,
      createdAt: now,
      updatedAt: now,
    );

    final allPelayan = await getAllPelayan();
    allPelayan.add(pelayan);
    await _savePelayan(allPelayan);

    return pelayan;
  }

  /// Update Pelayan
  Future<Pelayan?> updatePelayan(String id, {
    String? nama,
    String? noTelepon,
    String? posisi,
    bool? isAktif,
  }) async {
    final allPelayan = await getAllPelayan();
    int index = allPelayan.indexWhere((p) => p.id == id);

    if (index == -1) return null;

    final updated = allPelayan[index].copyWith(
      nama: nama,
      noTelepon: noTelepon,
      posisi: posisi,
      isAktif: isAktif,
      updatedAt: DateTime.now(),
    );

    allPelayan[index] = updated;
    await _savePelayan(allPelayan);

    return updated;
  }

  /// Delete Pelayan
  Future<bool> deletePelayan(String id) async {
    final allPelayan = await getAllPelayan();
    allPelayan.removeWhere((p) => p.id == id);
    await _savePelayan(allPelayan);
    return true;
  }

  /// Get active Pelayan only
  Future<List<Pelayan>> getActivePelayan() async {
    final allPelayan = await getAllPelayan();
    return allPelayan.where((p) => p.isAktif).toList();
  }

  /// Search Pelayan by name
  Future<List<Pelayan>> searchPelayan(String query) async {
    final allPelayan = await getAllPelayan();
    return allPelayan
        .where((p) => p.nama.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Get Pelayan count
  Future<int> getPelayaniCount() async {
    final allPelayan = await getAllPelayan();
    return allPelayan.length;
  }

  /// Get active Pelayan count
  Future<int> getActivePelayaniCount() async {
    final activePelayan = await getActivePelayan();
    return activePelayan.length;
  }

  /// Save all Pelayan to SharedPreferences
  Future<void> _savePelayan(List<Pelayan> pelayaniList) async {
    final jsonList = pelayaniList.map((p) => p.toJson()).toList();
    await _prefs.setString(_pelayaniKey, jsonEncode(jsonList));
  }
}

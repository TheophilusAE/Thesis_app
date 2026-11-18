import 'package:flutter/foundation.dart';

import '../models/ibadah.dart';
import '../models/pelayan.dart';
import '../services/supabase_service.dart';
import '../utils/recurrence.dart';

/// Pure date rules for worship series (unit-tested). Reuses the tested
/// `generateRecurrenceDates` from utils/recurrence.dart.
class IbadahDates {
  IbadahDates._();

  /// Dates to create for a new series: the first [horizonDays] days from
  /// [start] (just [start] for a one-off), cut at [endDate].
  static List<DateTime> forNewSeries({
    required DateTime start,
    required String pola,
    DateTime? endDate,
    int horizonDays = defaultRecurrenceHorizonDays,
  }) {
    final first = DateTime(start.year, start.month, start.day);
    if (pola == polaNone) return [first];
    return generateRecurrenceDates(first, pola, horizonDays: horizonDays)
        .where((d) => endDate == null || !d.isAfter(endDate))
        .toList();
  }

  /// Future dates (today … today + [horizonDays]) of an existing recurring
  /// series, keeping the series' own rhythm (same weekday / day of month).
  static List<DateTime> upcomingForSeries(
    IbadahSeries series, {
    required DateTime today,
    int horizonDays = defaultRecurrenceHorizonDays,
  }) {
    if (!series.isRecurring || !series.isActive) return const [];
    final from = DateTime(today.year, today.month, today.day);
    final until = DateTime(from.year, from.month, from.day + horizonDays);
    final span = until.difference(series.startDate).inDays;
    if (span < 0) return const [];
    return generateRecurrenceDates(series.startDate, series.pola, horizonDays: span)
        .where((d) => !d.isBefore(from))
        .where((d) => series.endDate == null || !d.isAfter(series.endDate!))
        .toList();
  }
}

/// Worship schedule (Jadwal Ibadah) state: series, upcoming dates, and the
/// pelayan duties + rehearsals linked to a date.
class IbadahProvider extends ChangeNotifier {
  IbadahProvider({SupabaseService? service}) : _service = service ?? SupabaseService();

  final SupabaseService _service;

  List<IbadahOccurrence> _occurrences = [];
  List<IbadahSeries> _series = [];
  bool _isLoading = false;
  String? _error;

  List<IbadahOccurrence> get occurrences => _occurrences;
  List<IbadahSeries> get series => _series;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Today's (non-cancelled) worship dates — used by the check-in screens.
  List<IbadahOccurrence> occurrencesOn(DateTime day) => _occurrences
      .where((o) =>
          !o.isCancelled &&
          o.tanggal.year == day.year &&
          o.tanggal.month == day.month &&
          o.tanggal.day == day.day)
      .toList();

  IbadahSeries? seriesById(String id) {
    for (final s in _series) {
      if (s.id == id) return s;
    }
    return null;
  }

  static String _message(Object e) {
    final m = e.toString();
    final i = m.indexOf('message: ');
    if (i >= 0) {
      final rest = m.substring(i + 9);
      final end = rest.indexOf(',');
      return end > 0 ? rest.substring(0, end) : rest;
    }
    return m.replaceFirst('Exception: ', '');
  }

  Future<void> load({DateTime? from, int days = 60}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final start = from ?? DateTime.now();
      final f = DateTime(start.year, start.month, start.day);
      final results = await Future.wait([
        _service.getIbadahOccurrences(f, f.add(Duration(days: days))),
        _service.getIbadahSeries(),
      ]);
      _occurrences = results[0].map(IbadahOccurrence.fromJson).toList();
      _series = results[1].map(IbadahSeries.fromJson).toList();
    } catch (e) {
      _error = SupabaseService.isMissingRelation(e)
          ? 'Fitur Jadwal Ibadah belum aktif. Jalankan migration_scheduling_v2.sql.'
          : 'Gagal memuat jadwal ibadah: ${_message(e)}';
      debugPrint('IbadahProvider.load: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Creates a series and its first dates. Returns null or an error message.
  Future<String?> createSeries(IbadahSeries draft) async {
    final dates = IbadahDates.forNewSeries(
      start: draft.startDate,
      pola: draft.pola,
      endDate: draft.endDate,
    );
    if (dates.isEmpty) return 'Tidak ada tanggal ibadah dalam rentang yang dipilih.';
    try {
      await _service.createIbadahSeries(draft.toCreateJson(), dates);
      await load();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  /// Keeps recurring series filled 90 days ahead. Safe to call often:
  /// existing dates are never touched. Silently skips series the admin
  /// may not extend.
  Future<int> ensureHorizon({DateTime? today}) async {
    var added = 0;
    final now = today ?? DateTime.now();
    for (final s in _series.where((s) => s.isRecurring && s.isActive)) {
      final dates = IbadahDates.upcomingForSeries(s, today: now);
      if (dates.isEmpty) continue;
      try {
        added += await _service.ensureIbadahOccurrences(s.id, dates.take(120).toList());
      } catch (e) {
        debugPrint('ensureHorizon(${s.id}): $e');
      }
    }
    if (added > 0) await load();
    return added;
  }

  /// Super Admin: edit a series. Returns null or an error message.
  Future<String?> updateSeries(String seriesId, Map<String, dynamic> changes) async {
    try {
      await _service.updateIbadahSeries(seriesId, changes);
      await load();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  /// Super Admin: cancel or restore one date.
  Future<String?> setOccurrenceCancelled(String occurrenceId, bool cancelled) async {
    try {
      await _service.updateIbadahOccurrence(
          occurrenceId, {'status': cancelled ? 'cancelled' : 'scheduled'});
      await load();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  /// One input for a worship date: assigns pelayan duties (date/time/type
  /// come from the date itself) and, optionally, a rehearsal for the same
  /// pelayan. Returns null or an error message.
  Future<String?> assignPelayanan({
    required IbadahOccurrence occurrence,
    required List<Pelayan> pelayan,
    String? notes,
    RehearsalInput? rehearsal,
  }) async {
    if (pelayan.isEmpty) return 'Pilih minimal satu pelayan.';
    try {
      for (final p in pelayan) {
        await _service.addSchedule({
          'occurrence_id': occurrence.id,
          'pelayan_id': p.id,
          'pelayan_name': p.nama,
          'pelayan_position': p.posisi,
          'notes': (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
          // Filled from the worship date by trigger; sent for the NOT NULL
          // column on databases where the trigger isn't installed yet.
          'service_date': DateTime(occurrence.tanggal.year, occurrence.tanggal.month,
                  occurrence.tanggal.day, 12)
              .toIso8601String(),
          'start_time': occurrence.startTime,
          'end_time': occurrence.endTime,
          'service_type': occurrence.jenis,
        });
      }
      if (rehearsal != null) {
        await _service.addTrainingSchedule({
          'occurrence_id': occurrence.id,
          'nama': rehearsal.nama.trim().isEmpty ? 'Latihan ${occurrence.nama}' : rehearsal.nama.trim(),
          'training_date': rehearsal.date.toIso8601String(),
          'start_time': rehearsal.startTime,
          'end_time': rehearsal.endTime,
          'deskripsi': rehearsal.deskripsi,
          'pelayan_ids': pelayan.map((p) => p.id).toList(),
          'lokasi': rehearsal.lokasi.trim().isEmpty ? occurrence.lokasi : rehearsal.lokasi.trim(),
        });
      }
      return null;
    } catch (e) {
      return _message(e);
    }
  }
}

/// Optional rehearsal created together with the duty assignment.
class RehearsalInput {
  final String nama;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String lokasi;
  final String deskripsi;

  const RehearsalInput({
    this.nama = '',
    required this.date,
    required this.startTime,
    this.endTime = '',
    this.lokasi = '',
    this.deskripsi = '',
  });
}

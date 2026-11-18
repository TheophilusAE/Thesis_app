import '../models/attendance_confirmation.dart';
import '../models/event.dart';
import '../models/feedback.dart';
import '../models/ibadah.dart';
import '../models/service_schedule.dart';

/// Rule-based, explainable decision support for church activity planning
/// (thesis RQ4 / OBJ4: "rekomendasi ... berdasarkan data kehadiran jemaat,
/// kapasitas gedung, riwayat kegiatan, dan feedback jemaat").
///
/// Pure Dart with no I/O, so every rule is unit-testable and the same input
/// always produces the same output. Each recommendation carries the numbers
/// that triggered it ([ActivityRecommendation.reason]) and the data it was
/// computed from ([ActivityRecommendation.dataBasis]). Output is aggregate
/// only — no member names or ids ever appear in a recommendation.

enum RecommendationSeverity { warning, attention, positive, info }

enum RecommendationCategory { kapasitas, kehadiran, kegiatan, feedback, data }

class ActivityRecommendation {
  final RecommendationCategory category;
  final RecommendationSeverity severity;
  final String title;
  final String reason;
  final String dataBasis;

  const ActivityRecommendation({
    required this.category,
    required this.severity,
    required this.title,
    required this.reason,
    required this.dataBasis,
  });
}

/// An event together with its current headcount
/// (from `get_event_registration_count`).
class EventWithRegistration {
  final ChurchEvent event;
  final int registeredCount;

  const EventWithRegistration(this.event, this.registeredCount);
}

class RecommendationInput {
  final List<ServiceSchedule> schedules;
  final List<AttendanceConfirmation> attendance;
  final List<UserFeedback> feedback;
  final List<EventWithRegistration> events;
  final DateTime now;
  final int? buildingCapacity;
  /// Worship dates (scheduling v2). Attendance rows with an occurrence id
  /// are counted per these dates; legacy rows still go through [schedules].
  final List<IbadahOccurrence> ibadah;

  const RecommendationInput({
    required this.schedules,
    required this.attendance,
    required this.feedback,
    required this.events,
    required this.now,
    required this.buildingCapacity,
    this.ibadah = const [],
  });
}

/// How much data the result was computed from (shown on screen so the
/// admin can judge how reliable the recommendations are).
class RecommendationSummary {
  final int serviceOccurrences;
  final int attendanceRecords;
  final int feedbackConsidered;
  final int eventsConsidered;
  final int? buildingCapacity;

  const RecommendationSummary({
    required this.serviceOccurrences,
    required this.attendanceRecords,
    required this.feedbackConsidered,
    required this.eventsConsidered,
    required this.buildingCapacity,
  });
}

class RecommendationResult {
  final List<ActivityRecommendation> recommendations;
  final RecommendationSummary summary;

  const RecommendationResult(this.recommendations, this.summary);
}

/// One worship service on one day. `schedules` stores one row per Pelayan
/// duty, so several rows with the same service type and date are the same
/// service; attendance is the number of distinct people across all of them.
class ServiceOccurrence {
  final String serviceType;
  final DateTime date;
  final int attendees;

  const ServiceOccurrence(this.serviceType, this.date, this.attendees);
}

class RecommendationEngine {
  RecommendationEngine._();

  /// Minimum data points before any rule is allowed to draw a conclusion.
  static const int minDataPoints = 3;

  /// Window for utilization: mean of the most recent N services.
  static const int utilizationWindow = 4;

  /// Trend compares the last N services with the N before them.
  static const int trendWindow = 3;

  static const double highUtilization = 0.90;
  static const double lowUtilization = 0.40;
  static const double trendThreshold = 0.20;
  static const double eventNearlyFull = 0.90;
  static const double eventLowFill = 0.30;
  static const int eventLowFillDays = 7;
  static const int feedbackWindowDays = 90;
  static const double lowRating = 3.0;
  static const double highRating = 4.5;

  static const Map<String, String> feedbackTypeLabels = {
    'event': 'Kegiatan',
    'facility': 'Fasilitas',
    'hospitality': 'Penyambutan & Pelayanan',
    'general': 'Umum',
  };

  static RecommendationResult generate(RecommendationInput input) {
    final occurrences = serviceOccurrences(input);
    final recent = _recentFeedback(input);
    final upcoming = input.events
        .where((e) => e.event.isActive && !e.event.date.isBefore(input.now))
        .toList();

    final recs = <ActivityRecommendation>[
      ..._attendanceRules(occurrences, input.buildingCapacity),
      ..._eventRules(upcoming, input),
      ..._feedbackRules(recent, input),
    ]..sort((a, b) {
        final bySeverity = a.severity.index.compareTo(b.severity.index);
        return bySeverity != 0 ? bySeverity : a.category.index.compareTo(b.category.index);
      });

    final countedOccurrences = occurrences.values.fold<int>(0, (s, l) => s + l.length);
    return RecommendationResult(
      recs,
      RecommendationSummary(
        serviceOccurrences: countedOccurrences,
        attendanceRecords: input.attendance.where((a) => a.confirmed).length,
        feedbackConsidered: recent.length,
        eventsConsidered: upcoming.length,
        buildingCapacity: input.buildingCapacity,
      ),
    );
  }

  /// Past services that have at least one confirmed attendance record,
  /// grouped by service type and sorted oldest → newest. Services with no
  /// attendance data at all are left out: an empty record means "not
  /// recorded", not "nobody came".
  static Map<String, List<ServiceOccurrence>> serviceOccurrences(RecommendationInput input) {
    final today = DateTime(input.now.year, input.now.month, input.now.day);
    final attendeesBySchedule = <String, Set<String>>{};
    final attendeesByOccurrence = <String, Set<String>>{};
    for (final a in input.attendance) {
      if (!a.confirmed) continue;
      if (a.occurrenceId != null) {
        attendeesByOccurrence.putIfAbsent(a.occurrenceId!, () => {}).add(a.userId);
      } else if (a.serviceScheduleId.isNotEmpty) {
        attendeesBySchedule.putIfAbsent(a.serviceScheduleId, () => {}).add(a.userId);
      }
    }

    final grouped = <String, Map<DateTime, Set<String>>>{};
    for (final s in input.schedules) {
      final day = DateTime(s.serviceDate.year, s.serviceDate.month, s.serviceDate.day);
      if (day.isAfter(today)) continue;
      final people = attendeesBySchedule[s.id];
      if (people == null || people.isEmpty) continue;
      grouped
          .putIfAbsent(s.serviceType, () => {})
          .putIfAbsent(day, () => <String>{})
          .addAll(people);
    }
    // Worship dates (v2): one occurrence = one service; QR check-ins point here.
    for (final o in input.ibadah) {
      if (o.isCancelled || o.tanggal.isAfter(today)) continue;
      final people = attendeesByOccurrence[o.id];
      if (people == null || people.isEmpty) continue;
      grouped
          .putIfAbsent(o.jenis, () => {})
          .putIfAbsent(o.tanggal, () => <String>{})
          .addAll(people);
    }

    return grouped.map((type, byDay) {
      final list = byDay.entries
          .map((e) => ServiceOccurrence(type, e.key, e.value.length))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return MapEntry(type, list);
    });
  }

  static List<ActivityRecommendation> _attendanceRules(
    Map<String, List<ServiceOccurrence>> byType,
    int? capacity,
  ) {
    final recs = <ActivityRecommendation>[];
    final insufficient = <String>[];

    if (capacity == null) {
      recs.add(const ActivityRecommendation(
        category: RecommendationCategory.data,
        severity: RecommendationSeverity.info,
        title: 'Kapasitas gedung belum dikonfigurasi',
        reason: 'Rekomendasi tingkat keterisian ibadah dilewati karena kapasitas gedung '
            'belum diatur. Analisis tren kehadiran tetap dijalankan.',
        dataBasis: 'Pengaturan ChurchConfig.buildingCapacity',
      ));
    }

    for (final entry in byType.entries) {
      final type = entry.key;
      final list = entry.value;
      if (list.length < minDataPoints) {
        insufficient.add('$type (${list.length})');
        continue;
      }

      // Utilization: mean of the most recent services vs. building capacity.
      if (capacity != null && capacity > 0) {
        final window = list.sublist(list.length - _min(utilizationWindow, list.length));
        final avg = _mean(window.map((o) => o.attendees));
        final ratio = avg / capacity;
        final pct = (ratio * 100).round();
        final basis = 'Rata-rata ${window.length} ${type.toLowerCase()} terakhir '
            '(${_fmt(avg)} orang) dibanding kapasitas gedung $capacity kursi';
        if (ratio >= highUtilization) {
          recs.add(ActivityRecommendation(
            category: RecommendationCategory.kapasitas,
            severity: RecommendationSeverity.warning,
            title: '$type hampir penuh ($pct%)',
            reason: 'Kehadiran rata-rata mencapai $pct% kapasitas gedung. Pertimbangkan '
                'menambah sesi ibadah atau menyiapkan kursi/ruang tambahan.',
            dataBasis: basis,
          ));
        } else if (ratio <= lowUtilization) {
          recs.add(ActivityRecommendation(
            category: RecommendationCategory.kapasitas,
            severity: RecommendationSeverity.attention,
            title: 'Keterisian $type rendah ($pct%)',
            reason: 'Kehadiran rata-rata hanya $pct% kapasitas gedung. Pertimbangkan '
                'mengevaluasi waktu pelaksanaan atau menggabungkan sesi.',
            dataBasis: basis,
          ));
        }
      }

      // Trend: last N services vs. the N before them.
      if (list.length >= trendWindow * 2) {
        final last = list.sublist(list.length - trendWindow);
        final prev = list.sublist(list.length - trendWindow * 2, list.length - trendWindow);
        final lastAvg = _mean(last.map((o) => o.attendees));
        final prevAvg = _mean(prev.map((o) => o.attendees));
        if (prevAvg > 0) {
          final change = (lastAvg - prevAvg) / prevAvg;
          final pct = (change.abs() * 100).round();
          final basis = 'Rata-rata $trendWindow ibadah terakhir (${_fmt(lastAvg)} orang) '
              'dibanding $trendWindow ibadah sebelumnya (${_fmt(prevAvg)} orang)';
          if (change <= -trendThreshold) {
            recs.add(ActivityRecommendation(
              category: RecommendationCategory.kehadiran,
              severity: RecommendationSeverity.attention,
              title: 'Kehadiran $type menurun $pct%',
              reason: 'Kehadiran turun $pct% dibanding periode sebelumnya. Pertimbangkan '
                  'evaluasi waktu, tema, atau penyampaian informasi ibadah ini.',
              dataBasis: basis,
            ));
          } else if (change >= trendThreshold) {
            recs.add(ActivityRecommendation(
              category: RecommendationCategory.kehadiran,
              severity: RecommendationSeverity.positive,
              title: 'Kehadiran $type meningkat $pct%',
              reason: 'Kehadiran naik $pct% dibanding periode sebelumnya. Siapkan kapasitas '
                  'dan jumlah pelayan yang memadai untuk ibadah berikutnya.',
              dataBasis: basis,
            ));
          }
        }
      }
    }

    if (byType.isEmpty) {
      recs.add(const ActivityRecommendation(
        category: RecommendationCategory.data,
        severity: RecommendationSeverity.info,
        title: 'Belum ada data kehadiran ibadah',
        reason: 'Belum ada presensi yang tercatat pada jadwal ibadah yang sudah lewat, '
            'sehingga rekomendasi kehadiran dan keterisian belum dapat dibuat.',
        dataBasis: 'Tabel attendance & schedules',
      ));
    } else if (insufficient.isNotEmpty) {
      recs.add(ActivityRecommendation(
        category: RecommendationCategory.data,
        severity: RecommendationSeverity.info,
        title: 'Data kehadiran belum cukup',
        reason: 'Minimal $minDataPoints ibadah dengan data presensi diperlukan untuk analisis. '
            'Belum cukup untuk: ${insufficient.join(', ')}.',
        dataBasis: 'Jumlah ibadah ber-presensi per jenis ibadah',
      ));
    }
    return recs;
  }

  static List<ActivityRecommendation> _eventRules(
    List<EventWithRegistration> upcoming,
    RecommendationInput input,
  ) {
    final recs = <ActivityRecommendation>[];
    final capacity = input.buildingCapacity;
    for (final e in upcoming) {
      final max = e.event.maxCapacity;
      final title = e.event.title;
      final count = e.registeredCount;

      if (capacity != null && max != null && max > capacity) {
        recs.add(ActivityRecommendation(
          category: RecommendationCategory.kapasitas,
          severity: RecommendationSeverity.warning,
          title: 'Kuota "$title" melebihi kapasitas gedung',
          reason: 'Kuota kegiatan ($max orang) lebih besar dari kapasitas gedung '
              '($capacity kursi). Sesuaikan kuota atau gunakan tempat yang lebih besar.',
          dataBasis: 'church_events.max_capacity dibanding kapasitas gedung',
        ));
      }
      if (max == null || max <= 0) continue;

      final ratio = count / max;
      final pct = (ratio * 100).round();
      final days = DateTime(e.event.date.year, e.event.date.month, e.event.date.day)
          .difference(DateTime(input.now.year, input.now.month, input.now.day))
          .inDays;
      final basis = '$count dari $max kuota terdaftar, $days hari sebelum kegiatan';

      if (count > max) {
        recs.add(ActivityRecommendation(
          category: RecommendationCategory.kegiatan,
          severity: RecommendationSeverity.warning,
          title: '"$title" melebihi kuota',
          reason: 'Pendaftar ($count orang) melebihi kuota ($max). Konfirmasi ulang peserta '
              'atau tambah kuota/ruang.',
          dataBasis: basis,
        ));
      } else if (ratio >= eventNearlyFull) {
        recs.add(ActivityRecommendation(
          category: RecommendationCategory.kegiatan,
          severity: RecommendationSeverity.warning,
          title: '"$title" hampir penuh ($pct%)',
          reason: 'Pendaftaran sudah $pct% dari kuota. Pertimbangkan menambah kuota atau '
              'membuka sesi tambahan bila tempat memungkinkan.',
          dataBasis: basis,
        ));
      } else if (days <= eventLowFillDays && ratio < eventLowFill) {
        recs.add(ActivityRecommendation(
          category: RecommendationCategory.kegiatan,
          severity: RecommendationSeverity.attention,
          title: 'Pendaftaran "$title" masih rendah ($pct%)',
          reason: 'Kegiatan tinggal $days hari lagi, tetapi pendaftaran baru $pct% dari kuota. '
              'Pertimbangkan menyebarkan pengumuman kembali.',
          dataBasis: basis,
        ));
      }
    }
    return recs;
  }

  static List<UserFeedback> _recentFeedback(RecommendationInput input) {
    final since = input.now.subtract(const Duration(days: feedbackWindowDays));
    return input.feedback
        .where((f) => f.rating >= 1 && !f.createdAt.isBefore(since))
        .toList();
  }

  static List<ActivityRecommendation> _feedbackRules(
    List<UserFeedback> recent,
    RecommendationInput input,
  ) {
    final recs = <ActivityRecommendation>[];

    final byType = <String, List<int>>{};
    for (final f in recent) {
      byType.putIfAbsent(f.feedbackType, () => []).add(f.rating);
    }
    for (final entry in byType.entries) {
      final ratings = entry.value;
      if (ratings.length < minDataPoints) continue;
      final avg = _mean(ratings);
      final area = feedbackTypeLabels[entry.key] ?? entry.key;
      final basis = '${ratings.length} feedback dalam $feedbackWindowDays hari terakhir, '
          'rata-rata ${_fmt(avg)}/5';
      if (avg < lowRating) {
        recs.add(ActivityRecommendation(
          category: RecommendationCategory.feedback,
          severity: RecommendationSeverity.warning,
          title: 'Penilaian $area rendah (${_fmt(avg)}/5)',
          reason: 'Rata-rata penilaian jemaat untuk $area di bawah ${_fmt(lowRating)}. '
              'Tinjau isi feedback dan prioritaskan perbaikan di area ini.',
          dataBasis: basis,
        ));
      } else if (avg >= highRating) {
        recs.add(ActivityRecommendation(
          category: RecommendationCategory.feedback,
          severity: RecommendationSeverity.positive,
          title: 'Penilaian $area sangat baik (${_fmt(avg)}/5)',
          reason: 'Jemaat menilai $area sangat baik. Pertahankan cara pelaksanaan saat ini.',
          dataBasis: basis,
        ));
      }
    }

    // Past events whose linked feedback is poor.
    final eventsById = {for (final e in input.events) e.event.id: e.event};
    final byEvent = <String, List<UserFeedback>>{};
    for (final f in recent) {
      final id = f.eventId;
      if (id == null || id.isEmpty) continue;
      byEvent.putIfAbsent(id, () => []).add(f);
    }
    for (final entry in byEvent.entries) {
      final items = entry.value;
      if (items.length < minDataPoints) continue;
      final event = eventsById[entry.key];
      if (event != null && !event.date.isBefore(input.now)) continue;
      final avg = _mean(items.map((f) => f.rating));
      if (avg >= lowRating) continue;
      final name = event?.title ?? items.first.eventName ?? 'kegiatan';
      recs.add(ActivityRecommendation(
        category: RecommendationCategory.kegiatan,
        severity: RecommendationSeverity.attention,
        title: 'Evaluasi kegiatan "$name"',
        reason: 'Feedback untuk kegiatan ini rata-rata ${_fmt(avg)}/5. Gunakan masukan '
            'jemaat sebelum menyelenggarakan kegiatan sejenis.',
        dataBasis: '${items.length} feedback terkait kegiatan ini',
      ));
    }
    return recs;
  }

  static int _min(int a, int b) => a < b ? a : b;

  static double _mean(Iterable<num> values) {
    var sum = 0.0;
    var n = 0;
    for (final v in values) {
      sum += v;
      n++;
    }
    return n == 0 ? 0 : sum / n;
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

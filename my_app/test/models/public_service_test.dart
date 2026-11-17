import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/admin_category.dart';
import 'package:my_app/models/public_service.dart';

void main() {
  test('public slots are parsed and grouped by date, sorted by start time', () {
    final slots = [
      {'service_type': 'Ibadah Malam', 'service_date': '2026-11-22', 'start_time': '18:00', 'end_time': '20:00'},
      {'service_type': 'Ibadah Minggu', 'service_date': '2026-11-22', 'start_time': '07:00', 'end_time': '09:00'},
      {'service_type': 'Doa Syafaat', 'service_date': '2026-11-19', 'start_time': '19:00', 'end_time': ''},
    ].map(PublicServiceSlot.fromJson).toList();

    final groups = PublicServiceSlot.groupByDate(slots);

    expect(groups.map((g) => g.key), [DateTime(2026, 11, 19), DateTime(2026, 11, 22)]);
    expect(groups.last.value.map((s) => s.serviceType), ['Ibadah Minggu', 'Ibadah Malam']);
    expect(groups.first.value.single.timeLabel, '19:00');
    expect(groups.last.value.first.timeLabel, '07:00 – 09:00');
  });

  test('a public slot never carries pelayan data', () {
    final slot = PublicServiceSlot.fromJson({
      'service_type': 'Ibadah Minggu',
      'service_date': '2026-11-22',
      'start_time': '07:00',
      'end_time': '09:00',
      'pelayan_name': 'should be ignored',
    });
    expect(slot.serviceType, 'Ibadah Minggu');
  });

  test('category codes are database-safe slugs', () {
    expect(AdminCategory.codeFromName('Sekolah Minggu'), 'sekolah_minggu');
    expect(AdminCategory.codeFromName('  Pemuda & Remaja! '), 'pemuda_remaja');
    expect(AdminCategory.codeFromName('***'), '');
  });
}

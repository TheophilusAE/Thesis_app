import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/church_group.dart';

void main() {
  group('Group', () {
    test('fromJson applies defaults for optional fields', () {
      final churchGroup = ChurchGroup.fromJson({
        'id': 'k1',
        'nama': 'Group Kasih',
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      expect(churchGroup.wilayah, '');
      expect(churchGroup.isActive, isTrue);
    });

    test('toSupabaseJson omits id/timestamps', () {
      final churchGroup = ChurchGroup(
        id: '',
        nama: 'Group Sukacita',
        wilayah: 'Utara',
        leaderName: 'Budi',
        leaderPhone: '081234567890',
        isActive: false,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final data = churchGroup.toSupabaseJson();
      expect(data.containsKey('id'), isFalse);
      expect(data['is_active'], isFalse);
      expect(data['leader_phone'], '081234567890');
    });

    test('copyWith preserves untouched fields', () {
      final churchGroup = ChurchGroup(
        id: 'k2',
        nama: 'Group Damai',
        isActive: true,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final updated = churchGroup.copyWith(isActive: false);
      expect(updated.isActive, isFalse);
      expect(updated.nama, 'Group Damai');
    });
  });
}

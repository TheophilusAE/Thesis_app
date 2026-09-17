import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/komsel.dart';

void main() {
  group('Komsel', () {
    test('fromJson applies defaults for optional fields', () {
      final komsel = Komsel.fromJson({
        'id': 'k1',
        'nama': 'Komsel Kasih',
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      expect(komsel.wilayah, '');
      expect(komsel.isActive, isTrue);
    });

    test('toSupabaseJson omits id/timestamps', () {
      final komsel = Komsel(
        id: '',
        nama: 'Komsel Sukacita',
        wilayah: 'Utara',
        leaderName: 'Budi',
        leaderPhone: '081234567890',
        isActive: false,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final data = komsel.toSupabaseJson();
      expect(data.containsKey('id'), isFalse);
      expect(data['is_active'], isFalse);
      expect(data['leader_phone'], '081234567890');
    });

    test('copyWith preserves untouched fields', () {
      final komsel = Komsel(
        id: 'k2',
        nama: 'Komsel Damai',
        isActive: true,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final updated = komsel.copyWith(isActive: false);
      expect(updated.isActive, isFalse);
      expect(updated.nama, 'Komsel Damai');
    });
  });
}

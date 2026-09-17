import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/prayer_request.dart';

void main() {
  group('PrayerRequest', () {
    test('fromJson applies defaults for category/status when absent', () {
      final request = PrayerRequest.fromJson({
        'id': 'pr-1',
        'user_id': 'u1',
        'content': 'Mohon doakan kesembuhan',
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      expect(request.category, 'pribadi');
      expect(request.status, 'baru');
      expect(request.isAnonymous, isFalse);
    });

    test('toSupabaseJson omits id/timestamps', () {
      final request = PrayerRequest(
        id: '',
        userId: 'u2',
        userName: 'Budi',
        category: 'keluarga',
        content: 'Doakan keluarga saya',
        isAnonymous: true,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final data = request.toSupabaseJson();
      expect(data.containsKey('id'), isFalse);
      expect(data.containsKey('created_at'), isFalse);
      expect(data['is_anonymous'], isTrue);
      expect(data['category'], 'keluarga');
    });

    test('copyWith updates status and updatedAt independently', () {
      final request = PrayerRequest(
        id: 'pr-3',
        userId: 'u3',
        userName: 'Siti',
        category: 'pribadi',
        content: 'Doa syukur',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final updated = request.copyWith(status: 'terjawab');
      expect(updated.status, 'terjawab');
      expect(updated.content, request.content);
    });
  });
}

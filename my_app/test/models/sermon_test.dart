import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/sermon.dart';

Sermon _sermon(String url, {String? thumbnailUrl}) {
  return Sermon(
    id: 's1',
    title: 'Khotbah',
    mediaUrl: url,
    thumbnailUrl: thumbnailUrl,
    sermonDate: DateTime.utc(2026, 1, 1),
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('Sermon.youtubeVideoId', () {
    test('extracts id from a watch?v= URL', () {
      expect(_sermon('https://www.youtube.com/watch?v=abc123XYZ').youtubeVideoId, 'abc123XYZ');
    });

    test('extracts id from a youtu.be short URL', () {
      expect(_sermon('https://youtu.be/abc123XYZ').youtubeVideoId, 'abc123XYZ');
    });

    test('extracts id from a /live/ URL', () {
      expect(_sermon('https://www.youtube.com/live/abc123XYZ').youtubeVideoId, 'abc123XYZ');
    });

    test('returns null for a non-YouTube URL', () {
      expect(_sermon('https://example.com/audio.mp3').youtubeVideoId, isNull);
    });

    test('returns null for an unparseable URL', () {
      expect(_sermon('not a url').youtubeVideoId, isNull);
    });
  });

  group('Sermon.resolvedThumbnailUrl', () {
    test('prefers an explicit thumbnail_url over the YouTube fallback', () {
      final sermon = _sermon(
        'https://www.youtube.com/watch?v=abc123XYZ',
        thumbnailUrl: 'https://example.com/custom.jpg',
      );
      expect(sermon.resolvedThumbnailUrl, 'https://example.com/custom.jpg');
    });

    test('falls back to the YouTube thumbnail CDN when no explicit thumbnail is set', () {
      final sermon = _sermon('https://www.youtube.com/watch?v=abc123XYZ');
      expect(sermon.resolvedThumbnailUrl, 'https://img.youtube.com/vi/abc123XYZ/hqdefault.jpg');
    });

    test('returns null when neither an explicit thumbnail nor a YouTube id is available', () {
      final sermon = _sermon('https://example.com/audio.mp3');
      expect(sermon.resolvedThumbnailUrl, isNull);
    });
  });

  group('Sermon JSON', () {
    test('toSupabaseJson omits id/timestamps', () {
      final data = _sermon('https://youtu.be/abc123').toSupabaseJson();
      expect(data.containsKey('id'), isFalse);
      expect(data.containsKey('created_at'), isFalse);
      expect(data['media_url'], 'https://youtu.be/abc123');
    });

    test('fromJson defaults media_type to youtube', () {
      final sermon = Sermon.fromJson({
        'id': 's2',
        'title': 'Khotbah 2',
        'media_url': 'https://youtu.be/xyz',
        'sermon_date': '2026-01-01T00:00:00.000Z',
        'created_at': '2026-01-01T00:00:00.000Z',
      });
      expect(sermon.mediaType, 'youtube');
      expect(sermon.isActive, isTrue);
    });
  });
}

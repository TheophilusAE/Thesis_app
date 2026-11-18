import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/event_registration.dart';
import 'package:my_app/utils/youtube_url.dart';

void main() {
  group('youtubeVideoId', () {
    test('handles watch, youtu.be, live, embed and shorts links', () {
      expect(youtubeVideoId('https://www.youtube.com/watch?v=abc123'), 'abc123');
      expect(youtubeVideoId('https://youtu.be/abc123'), 'abc123');
      expect(youtubeVideoId('https://www.youtube.com/live/abc123?si=x'), 'abc123');
      expect(youtubeVideoId('https://youtube.com/embed/abc123'), 'abc123');
      expect(youtubeVideoId('https://m.youtube.com/shorts/abc123'), 'abc123');
    });

    test('returns null for other sites and junk', () {
      expect(youtubeVideoId('https://vimeo.com/123'), isNull);
      expect(youtubeVideoId('https://notyoutube.com.evil/watch?v=x'), isNull);
      expect(youtubeVideoId(''), isNull);
      expect(youtubeVideoId(null), isNull);
    });
  });

  group('validateYoutubeUrl (same rule as the database CHECK)', () {
    test('empty is allowed (link is optional)', () {
      expect(validateYoutubeUrl(''), isNull);
      expect(validateYoutubeUrl(null), isNull);
    });

    test('accepts https YouTube links', () {
      expect(validateYoutubeUrl('https://www.youtube.com/live/abc'), isNull);
      expect(validateYoutubeUrl('https://youtu.be/abc'), isNull);
      expect(validateYoutubeUrl('https://m.youtube.com/watch?v=abc'), isNull);
    });

    test('rejects http, other hosts and bare homepages', () {
      expect(validateYoutubeUrl('http://youtube.com/live/abc'), isNotNull);
      expect(validateYoutubeUrl('https://youtube.com.evil.com/live/abc'), isNotNull);
      expect(validateYoutubeUrl('https://www.youtube.com/'), isNotNull);
      expect(validateYoutubeUrl('youtube.com/live/abc'), isNotNull);
    });
  });

  group('event booking status', () {
    Map<String, dynamic> row(String? status) => {
          'id': 'r1',
          'event_id': 'e1',
          'user_id': 'u1',
          'registered_at': '2026-11-01T00:00:00Z',
          'status': ?status,
        };

    test('old rows without status count as an active booking', () {
      final r = EventRegistration.fromJson(row(null));
      expect(r.status, RegistrationStatus.registered);
      expect(r.isActive, isTrue);
      expect(r.isAttended, isFalse);
    });

    test('attended and cancelled are distinguished', () {
      expect(EventRegistration.fromJson(row('attended')).isAttended, isTrue);
      expect(EventRegistration.fromJson(row('cancelled')).isActive, isFalse);
      expect(RegistrationStatus.label('attended'), contains('check-in'));
    });
  });
}

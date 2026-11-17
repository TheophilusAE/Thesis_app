import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/services/devotional_bookmarks.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('toggle saves, then unsaves, a devotional', () async {
    final bookmarks = DevotionalBookmarks();

    expect(await bookmarks.toggle('alice', 'dev-1'), isTrue);
    expect(await bookmarks.load('alice'), {'dev-1'});

    expect(await bookmarks.toggle('alice', 'dev-1'), isFalse);
    expect(await bookmarks.load('alice'), isEmpty);
  });

  test('bookmarks are per account', () async {
    final bookmarks = DevotionalBookmarks();
    await bookmarks.toggle('alice', 'dev-1');

    expect(await bookmarks.load('bob'), isEmpty);
  });
}

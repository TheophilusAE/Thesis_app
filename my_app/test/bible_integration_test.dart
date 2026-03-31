import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/services/bible_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xml/xml.dart' as xml;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Indonesian XML has complete Bible structure', () async {
    final raw = await rootBundle.loadString('assets/bible/IndonesianBible.xml');
    final doc = xml.XmlDocument.parse(raw);

    final bible = doc.getElement('bible');
    expect(bible, isNotNull);

    final books = bible!.findAllElements('book');
    final chapters = bible.findAllElements('chapter');
    final verses = bible.findAllElements('verse');

    expect(books.length, 66);
    expect(chapters.length, 1189);
    expect(verses.length, 31102);
  });

  test('BibleService loads Genesis chapter from XML-seeded database', () async {
    final service = BibleService();

    final verses = await service.getVersesByBook('Kejadian', 1);

    expect(verses, isNotEmpty);
    expect(verses.length, greaterThan(20));

    final firstVerse = verses.firstWhere((v) => v.verse == 1);
    expect(firstVerse.text.toLowerCase(), contains('pada mulanya'));
  });
}

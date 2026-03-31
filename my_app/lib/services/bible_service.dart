import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'dart:convert';
import 'package:xml/xml.dart' as xml;
import '../models/bible_verse.dart';

/// Bible Service - Fully Offline (SQLite)
class BibleService {
  static const _dbName = 'bible.db';
  static const _dbVersion = 4;
  static const _seedAssetPath = 'assets/bible/IndonesianBible.xml';

  sqflite.Database? _database;
  List<BibleVerse>? _fallbackVerses;

  bool _shouldUseFallback(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('databasefactory not initialized') ||
      message.contains('no such module: fts5') ||
      message.contains('sqlite_error') ||
        message.contains('bad state') ||
        kIsWeb;
  }

  Future<void> _ensureFallbackLoaded() async {
    if (_fallbackVerses != null) {
      return;
    }

    _fallbackVerses = await _loadSeedVerses();
  }

  Future<List<BibleVerse>> _loadSeedVerses() async {
    final rawSeed = await rootBundle.loadString(_seedAssetPath);
    if (_seedAssetPath.toLowerCase().endsWith('.xml')) {
      return _parseXmlVerses(rawSeed);
    }

    final data = jsonDecode(rawSeed) as Map<String, dynamic>;
    final verses = (data['verses'] as List<dynamic>? ?? const []);
    return verses
        .map((entry) {
          final verseData = entry as Map<String, dynamic>;
          final book = (verseData['book'] as String?)?.trim();
          final chapter = (verseData['chapter'] as num?)?.toInt();
          final verse = (verseData['verse'] as num?)?.toInt();
          final text = (verseData['text'] as String?)?.trim();

          if (book == null ||
              book.isEmpty ||
              chapter == null ||
              chapter <= 0 ||
              verse == null ||
              verse <= 0 ||
              text == null ||
              text.isEmpty) {
            return null;
          }

          return BibleVerse(
            id: 0,
            book: book,
            chapter: chapter,
            verse: verse,
            text: text,
          );
        })
        .whereType<BibleVerse>()
        .toList(growable: false);
  }

  List<BibleVerse> _parseXmlVerses(String rawXml) {
    final document = xml.XmlDocument.parse(rawXml);
    final bibleElement = document.getElement('bible');
    if (bibleElement == null) {
      throw const FormatException('Invalid XML format: missing <bible> root element');
    }

    final canonicalBooks = getBibleBooks();
    final parsed = <BibleVerse>[];

    for (final testamentElement in bibleElement.findElements('testament')) {
      for (final bookElement in testamentElement.findElements('book')) {
        final bookNumber = int.tryParse((bookElement.getAttribute('number') ?? '').trim());
        if (bookNumber == null || bookNumber <= 0 || bookNumber > canonicalBooks.length) {
          continue;
        }

        final bookName = canonicalBooks[bookNumber - 1].name;
        for (final chapterElement in bookElement.findElements('chapter')) {
          final chapter = int.tryParse((chapterElement.getAttribute('number') ?? '').trim());
          if (chapter == null || chapter <= 0) {
            continue;
          }

          for (final verseElement in chapterElement.findElements('verse')) {
            final verse = int.tryParse((verseElement.getAttribute('number') ?? '').trim());
            final text = verseElement.innerText.trim();
            if (verse == null || verse <= 0 || text.isEmpty) {
              continue;
            }

            parsed.add(
              BibleVerse(
                id: 0,
                book: bookName,
                chapter: chapter,
                verse: verse,
                text: text,
              ),
            );
          }
        }
      }
    }

    return parsed;
  }

  Future<sqflite.Database> _getDatabase() async {
    if (_database != null) {
      return _database!;
    }

    final databaseRoot = await sqflite.getDatabasesPath();
    final databasePath = path.join(databaseRoot, _dbName);

    _database = await sqflite.openDatabase(
      databasePath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedDatabase(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Clear all old data and reseed with complete Bible
        await db.delete('verses');
        await db.delete('chapters');
        await db.delete('books');
        await db.execute('DROP TABLE IF EXISTS verses_fts');
        await _seedDatabase(db);
      },
    );

    return _database!;
  }

  Future<void> _createSchema(sqflite.Database db) async {
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        chapters INTEGER NOT NULL,
        testament TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book TEXT NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        text TEXT NOT NULL,
        UNIQUE(book, chapter, verse)
      )
    ''');

    await db.execute('''
      CREATE TABLE chapters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        chapter_number INTEGER NOT NULL,
        UNIQUE(book_id, chapter_number),
        FOREIGN KEY(book_id) REFERENCES books(id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_verses_book_chapter ON verses(book, chapter, verse)',
    );

    await db.execute('CREATE INDEX idx_verses_text ON verses(text)');
  }

  Future<void> _seedDatabase(sqflite.Database db) async {
    final verses = await _loadSeedVerses();

    if (verses.isEmpty) return;

    // Extract unique books and chapters from verses
    final bookChaptersMap = <String, Set<int>>{};
    
    for (final verseData in verses) {
      final book = verseData.book.trim();
      final chapter = verseData.chapter;

      if (book.isNotEmpty && chapter > 0) {
        bookChaptersMap.putIfAbsent(book, () => <int>{}).add(chapter);
      }
    }

    final batch = db.batch();
    final bookIds = <String, int>{};

    // Get canonical books for order and chapter counts
    final canonicalBooks = getBibleBooks();
    final bookOrder = <String, int>{};
    for (int i = 0; i < canonicalBooks.length; i++) {
      bookOrder[canonicalBooks[i].name] = i;
    }

    // Insert books
    for (final bookName in bookChaptersMap.keys) {
      final maxChapter = bookChaptersMap[bookName]!.reduce((a, b) => a > b ? a : b);
      final order = bookOrder[bookName] ?? 999;
      final testament = order < 39 ? 'old' : 'new';

      final id = await db.insert(
        'books',
        {
          'name': bookName,
          'chapters': maxChapter,
          'testament': testament,
        },
        conflictAlgorithm: sqflite.ConflictAlgorithm.ignore,
      );

      final existing = await db.query(
        'books',
        columns: ['id'],
        where: 'name = ?',
        whereArgs: [bookName],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        bookIds[bookName] = (existing.first['id'] as num).toInt();
      } else if (id > 0) {
        bookIds[bookName] = id;
      }
    }

    // Insert verses and chapters
    final chapterPairs = <String>{};
    for (final verseData in verses) {
      final book = verseData.book.trim();
      final chapter = verseData.chapter;
      final verse = verseData.verse;
      final text = verseData.text.trim();

      if (book.isEmpty || chapter <= 0 || verse <= 0 || text.isEmpty) {
        continue;
      }

      batch.insert(
        'verses',
        {
          'book': book,
          'chapter': chapter,
          'verse': verse,
          'text': text,
        },
        conflictAlgorithm: sqflite.ConflictAlgorithm.ignore,
      );

      final bookId = bookIds[book];
      if (bookId != null) {
        final chapterKey = '$bookId:$chapter';
        if (chapterPairs.add(chapterKey)) {
          batch.insert(
            'chapters',
            {
              'book_id': bookId,
              'chapter_number': chapter,
            },
            conflictAlgorithm: sqflite.ConflictAlgorithm.ignore,
          );
        }
      }
    }

    await batch.commit(noResult: true);
  }

  /// Get verses by book and chapter
  Future<List<BibleVerse>> getVersesByBook(String book, int chapter) async {
    if (kIsWeb) {
      await _ensureFallbackLoaded();
      return _fallbackVerses!
          .where((v) => v.book == book && v.chapter == chapter)
          .toList(growable: false);
    }

    try {
      final db = await _getDatabase();
      final rows = await db.query(
        'verses',
        where: 'book = ? AND chapter = ?',
        whereArgs: [book, chapter],
        orderBy: 'verse ASC',
      );

      return rows
          .map(
            (row) => BibleVerse(
              id: (row['id'] as num).toInt(),
              book: row['book'] as String,
              chapter: (row['chapter'] as num).toInt(),
              verse: (row['verse'] as num).toInt(),
              text: row['text'] as String,
            ),
          )
          .toList();
    } catch (e) {
      if (!_shouldUseFallback(e)) {
        rethrow;
      }

      await _ensureFallbackLoaded();
      return _fallbackVerses!
          .where((v) => v.book == book && v.chapter == chapter)
          .toList(growable: false);
    }
  }

  /// Search verses using SQLite LIKE (offline)
  Future<List<BibleVerse>> searchVerses(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return [];
    }

    if (kIsWeb) {
      await _ensureFallbackLoaded();
      final keyword = normalizedQuery.toLowerCase();
      return _fallbackVerses!
          .where((v) =>
              v.text.toLowerCase().contains(keyword) ||
              v.book.toLowerCase().contains(keyword))
          .take(100)
          .toList(growable: false);
    }

    try {
      final db = await _getDatabase();
      final likeArg = '%$normalizedQuery%';
      final rows = await db.rawQuery(
        '''
        SELECT id, book, chapter, verse, text
        FROM verses
        WHERE text LIKE ? OR book LIKE ?
        ORDER BY book ASC, chapter ASC, verse ASC
        LIMIT 100
        ''',
        [likeArg, likeArg],
      );

      return rows
          .map(
            (row) => BibleVerse(
              id: (row['id'] as num?)?.toInt() ?? 0,
              book: row['book'] as String,
              chapter: (row['chapter'] as num).toInt(),
              verse: (row['verse'] as num).toInt(),
              text: row['text'] as String,
            ),
          )
          .toList();
    } catch (e) {
      if (!_shouldUseFallback(e)) {
        rethrow;
      }

      await _ensureFallbackLoaded();
      final keyword = normalizedQuery.toLowerCase();
      return _fallbackVerses!
          .where((v) =>
              v.text.toLowerCase().contains(keyword) ||
              v.book.toLowerCase().contains(keyword))
          .take(100)
          .toList(growable: false);
    }
  }

  /// Check if chapter exists in local DB
  Future<bool> isChapterCached(String book, int chapter) async {
    if (kIsWeb) {
      await _ensureFallbackLoaded();
      return _fallbackVerses!
          .any((v) => v.book == book && v.chapter == chapter);
    }

    try {
      final db = await _getDatabase();
      final rows = await db.query(
        'verses',
        columns: ['id'],
        where: 'book = ? AND chapter = ?',
        whereArgs: [book, chapter],
        limit: 1,
      );
      return rows.isNotEmpty;
    } catch (e) {
      if (!_shouldUseFallback(e)) {
        rethrow;
      }

      await _ensureFallbackLoaded();
      return _fallbackVerses!
          .any((v) => v.book == book && v.chapter == chapter);
    }
  }

  /// Reset and reseed local Bible DB
  Future<void> clearAllCaches() async {
    _fallbackVerses = null;

    if (kIsWeb) {
      await _ensureFallbackLoaded();
      return;
    }

    final db = await _getDatabase();
    await db.delete('verses');
    await db.delete('chapters');
    await db.delete('books');
    await db.execute('DROP TABLE IF EXISTS verses_fts');
    await _seedDatabase(db);
  }

  /// Get list of all Bible books
  List<BibleBook> getBibleBooks() {
    return [
      // Perjanjian Lama - Torah
      BibleBook(name: 'Kejadian', chapters: 50),
      BibleBook(name: 'Keluaran', chapters: 40),
      BibleBook(name: 'Imamat', chapters: 27),
      BibleBook(name: 'Bilangan', chapters: 36),
      BibleBook(name: 'Ulangan', chapters: 34),
      
      // Perjanjian Lama - Sejarah
      BibleBook(name: 'Yosua', chapters: 24),
      BibleBook(name: 'Hakim-hakim', chapters: 21),
      BibleBook(name: 'Rut', chapters: 4),
      BibleBook(name: '1 Samuel', chapters: 31),
      BibleBook(name: '2 Samuel', chapters: 24),
      BibleBook(name: '1 Raja-raja', chapters: 22),
      BibleBook(name: '2 Raja-raja', chapters: 25),
      BibleBook(name: '1 Tawarikh', chapters: 29),
      BibleBook(name: '2 Tawarikh', chapters: 36),
      BibleBook(name: 'Ezra', chapters: 10),
      BibleBook(name: 'Nehemia', chapters: 13),
      BibleBook(name: 'Ester', chapters: 10),
      
      // Perjanjian Lama - Puisi & Kebijaksanaan
      BibleBook(name: 'Ayub', chapters: 42),
      BibleBook(name: 'Mazmur', chapters: 150),
      BibleBook(name: 'Amsal', chapters: 31),
      BibleBook(name: 'Pengkhotbah', chapters: 12),
      BibleBook(name: 'Kidung Agung', chapters: 8),
      
      // Perjanjian Lama - Nabi Besar
      BibleBook(name: 'Yesaya', chapters: 66),
      BibleBook(name: 'Yeremia', chapters: 52),
      BibleBook(name: 'Trenyina', chapters: 5),
      BibleBook(name: 'Yehezkiel', chapters: 48),
      BibleBook(name: 'Daniel', chapters: 12),
      
      // Perjanjian Lama - Nabi Kecil
      BibleBook(name: 'Hosea', chapters: 14),
      BibleBook(name: 'Yoel', chapters: 3),
      BibleBook(name: 'Amos', chapters: 9),
      BibleBook(name: 'Obaja', chapters: 1),
      BibleBook(name: 'Yunus', chapters: 4),
      BibleBook(name: 'Mikha', chapters: 7),
      BibleBook(name: 'Nahum', chapters: 3),
      BibleBook(name: 'Habakuk', chapters: 3),
      BibleBook(name: 'Zefanya', chapters: 3),
      BibleBook(name: 'Hagai', chapters: 2),
      BibleBook(name: 'Zakaria', chapters: 14),
      BibleBook(name: 'Maleakhi', chapters: 4),
      
      // Perjanjian Baru - Injil
      BibleBook(name: 'Matius', chapters: 28),
      BibleBook(name: 'Markus', chapters: 16),
      BibleBook(name: 'Lukas', chapters: 24),
      BibleBook(name: 'Yohanes', chapters: 21),
      
      // Perjanjian Baru - Sejarah
      BibleBook(name: 'Kisah Para Rasul', chapters: 28),
      
      // Perjanjian Baru - Surat Paulus
      BibleBook(name: 'Roma', chapters: 16),
      BibleBook(name: '1 Korintus', chapters: 16),
      BibleBook(name: '2 Korintus', chapters: 13),
      BibleBook(name: 'Galatia', chapters: 6),
      BibleBook(name: 'Efesus', chapters: 6),
      BibleBook(name: 'Filipi', chapters: 4),
      BibleBook(name: 'Kolose', chapters: 4),
      BibleBook(name: '1 Tesalonika', chapters: 5),
      BibleBook(name: '2 Tesalonika', chapters: 3),
      BibleBook(name: '1 Timotius', chapters: 6),
      BibleBook(name: '2 Timotius', chapters: 4),
      BibleBook(name: 'Titus', chapters: 3),
      BibleBook(name: 'Filemon', chapters: 1),
      
      // Perjanjian Baru - Surat-Surat Lain
      BibleBook(name: 'Ibrani', chapters: 13),
      BibleBook(name: 'Yakobus', chapters: 5),
      BibleBook(name: '1 Petrus', chapters: 5),
      BibleBook(name: '2 Petrus', chapters: 3),
      BibleBook(name: '1 Yohanes', chapters: 5),
      BibleBook(name: '2 Yohanes', chapters: 1),
      BibleBook(name: '3 Yohanes', chapters: 1),
      BibleBook(name: 'Yudas', chapters: 1),
      
      // Perjanjian Baru - Apokaliptik
      BibleBook(name: 'Wahyu', chapters: 22),
    ];
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/bible_verse.dart';

class BibleService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bible.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book TEXT NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        text TEXT NOT NULL
      )
    ''');

    // Insert sample Bible data (Indonesian Bible - Alkitab)
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    // Sample data for Genesis 1:1-5
    final sampleVerses = [
      {'book': 'Kejadian', 'chapter': 1, 'verse': 1, 'text': 'Pada mulanya Allah menciptakan langit dan bumi.'},
      {'book': 'Kejadian', 'chapter': 1, 'verse': 2, 'text': 'Bumi belum berbentuk dan kosong; gelap gulita menutupi samudera raya, dan Roh Allah melayang-layang di atas permukaan air.'},
      {'book': 'Kejadian', 'chapter': 1, 'verse': 3, 'text': 'Berfirmanlah Allah: "Jadilah terang." Lalu terang itu jadi.'},
      {'book': 'Kejadian', 'chapter': 1, 'verse': 4, 'text': 'Allah melihat bahwa terang itu baik, lalu dipisahkan-Nyalah terang itu dari gelap.'},
      {'book': 'Kejadian', 'chapter': 1, 'verse': 5, 'text': 'Dan Allah menamai terang itu siang, dan gelap itu malam. Jadilah petang dan jadilah pagi, itulah hari pertama.'},
      
      {'book': 'Yohanes', 'chapter': 3, 'verse': 16, 'text': 'Karena begitu besar kasih Allah akan dunia ini, sehingga Ia telah mengaruniakan Anak-Nya yang tunggal, supaya setiap orang yang percaya kepada-Nya tidak binasa, melainkan beroleh hidup yang kekal.'},
      
      {'book': 'Mazmur', 'chapter': 23, 'verse': 1, 'text': 'Mazmur Daud. TUHAN adalah gembalaku, takkan kekurangan aku.'},
      {'book': 'Mazmur', 'chapter': 23, 'verse': 2, 'text': 'Ia membaringkan aku di padang yang berumput hijau, Ia membimbing aku ke air yang tenang;'},
      {'book': 'Mazmur', 'chapter': 23, 'verse': 3, 'text': 'Ia menyegarkan jiwaku. Ia menuntun aku di jalan yang benar oleh karena nama-Nya.'},
    ];

    for (var verse in sampleVerses) {
      await db.insert('verses', verse);
    }
  }

  Future<List<BibleVerse>> getVersesByBook(String book, int chapter) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'verses',
      where: 'book = ? AND chapter = ?',
      whereArgs: [book, chapter],
      orderBy: 'verse ASC',
    );

    return List.generate(maps.length, (i) {
      return BibleVerse.fromJson(maps[i]);
    });
  }

  Future<List<BibleVerse>> searchVerses(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'verses',
      where: 'text LIKE ?',
      whereArgs: ['%$query%'],
      limit: 50,
    );

    return List.generate(maps.length, (i) {
      return BibleVerse.fromJson(maps[i]);
    });
  }

  List<BibleBook> getBibleBooks() {
    return [
      BibleBook(name: 'Kejadian', chapters: 50),
      BibleBook(name: 'Keluaran', chapters: 40),
      BibleBook(name: 'Imamat', chapters: 27),
      BibleBook(name: 'Bilangan', chapters: 36),
      BibleBook(name: 'Ulangan', chapters: 34),
      // Perjanjian Baru
      BibleBook(name: 'Matius', chapters: 28),
      BibleBook(name: 'Markus', chapters: 16),
      BibleBook(name: 'Lukas', chapters: 24),
      BibleBook(name: 'Yohanes', chapters: 21),
      BibleBook(name: 'Kisah Para Rasul', chapters: 28),
      // Add more books as needed
      BibleBook(name: 'Mazmur', chapters: 150),
      BibleBook(name: 'Amsal', chapters: 31),
    ];
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

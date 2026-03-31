import 'package:flutter/foundation.dart';
import '../models/bible_verse.dart';
import '../services/bible_service.dart';

class BibleProvider with ChangeNotifier {
  final BibleService _bibleService = BibleService();
  List<BibleVerse> _verses = [];
  List<BibleBook> _books = [];
  bool _isLoading = false;
  String? _error;

  List<BibleVerse> get verses => _verses;
  List<BibleBook> get books => _books;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BibleProvider() {
    _books = _bibleService.getBibleBooks();
  }

  Future<void> loadChapter(String book, int chapter) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _verses = await _bibleService.getVersesByBook(book, chapter);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchVerses(String query) async {
    if (query.isEmpty) {
      _verses = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _verses = await _bibleService.searchVerses(query);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

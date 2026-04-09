import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible_verse.dart';
import '../services/bible_service.dart';

class BibleProvider with ChangeNotifier {
  final BibleService _bibleService = BibleService();
  List<BibleVerse> _chapterVerses = [];
  List<BibleVerse> _searchResults = [];
  List<BibleBook> _books = [];
  bool _isLoading = false;
  String? _error;
  String _lastBook = 'Kejadian';
  int _lastChapter = 1;
  bool _isSearchMode = false;
  late final Future<void> _initializationFuture;

  List<BibleVerse> get verses => _isSearchMode ? _searchResults : _chapterVerses;
  List<BibleBook> get books => _books;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get lastBook => _lastBook;
  int get lastChapter => _lastChapter;

  BibleProvider() {
    _books = _bibleService.getBibleBooks();
    _initializationFuture = _loadLastPosition();
  }

  Future<void> ensureInitialized() => _initializationFuture;

  /// Load the last opened book and chapter from SharedPreferences
  Future<void> _loadLastPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastBook = prefs.getString('bible_last_book') ?? 'Kejadian';
      _lastChapter = prefs.getInt('bible_last_chapter') ?? 1;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading last position: $e');
    }
  }

  /// Save the current book and chapter to SharedPreferences
  Future<void> _saveLastPosition(String book, int chapter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bible_last_book', book);
      await prefs.setInt('bible_last_chapter', chapter);
      _lastBook = book;
      _lastChapter = chapter;
    } catch (e) {
      debugPrint('Error saving last position: $e');
    }
  }

  Future<void> loadChapter(String book, int chapter) async {
    _isLoading = true;
    _error = null;
    _isSearchMode = false;
    notifyListeners();

    try {
      _chapterVerses = await _bibleService.getVersesByBook(book, chapter);
      // Save the current position
      await _saveLastPosition(book, chapter);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchVerses(String query) async {
    if (query.isEmpty) {
      clearSearch();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _isSearchMode = true;
    notifyListeners();

    try {
      _searchResults = await _bibleService.searchVerses(query);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _isSearchMode = false;
    _searchResults = [];
    _error = null;
    notifyListeners();
  }
}

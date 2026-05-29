import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible_verse.dart';
import '../services/bible_service.dart';
import '../services/supabase_service.dart';

class BibleProvider with ChangeNotifier {
  List<BibleVerse> _chapterVerses = [];
  List<BibleVerse> _searchResults = [];
  final List<BibleBook> _books = [];
  bool _isLoading = false;
  String? _error;
  String _lastBook = 'Kejadian';
  int _lastChapter = 1;
  bool _isSearchMode = false;
  late final Future<void> _initializationFuture;

  final SupabaseService _supabaseService = SupabaseService();
  final BibleService _bibleService = BibleService();

  List<BibleVerse> get verses => _isSearchMode ? _searchResults : _chapterVerses;
  List<BibleBook> get books => _books;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get lastBook => _lastBook;
  int get lastChapter => _lastChapter;

  BibleProvider() {
    _books.addAll(_bibleService.getBibleBooks());
    _initializationFuture = _loadLastPosition();
  }

  Future<void> ensureInitialized() => _initializationFuture;

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
      // Try Supabase first, fall back to local SQLite
      List<BibleVerse> verses = await _loadFromSupabase(book, chapter);
      if (verses.isEmpty) {
        verses = await _loadFromLocal(book, chapter);
      }
      _chapterVerses = verses;
      await _saveLastPosition(book, chapter);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading chapter: $e');
      // Last resort: try local
      try {
        _chapterVerses = await _loadFromLocal(book, chapter);
      } catch (_) {}
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<BibleVerse>> _loadFromSupabase(String book, int chapter) async {
    try {
      final data = await _supabaseService.getBibleVerses(book, chapter);
      return data.map((e) => BibleVerse(
        id: (e['id'] as num?)?.toInt() ?? 0,
        book: e['book'] as String,
        chapter: (e['chapter'] as num).toInt(),
        verse: (e['verse'] as num).toInt(),
        text: e['text'] as String,
      )).toList();
    } catch (e) {
      debugPrint('Supabase bible load failed, using local: $e');
      return [];
    }
  }

  Future<List<BibleVerse>> _loadFromLocal(String book, int chapter) async {
    try {
      return await _bibleService.getVersesByBook(book, chapter);
    } catch (e) {
      debugPrint('Local bible load failed: $e');
      return [];
    }
  }

  Future<void> searchVerses(String query) async {
    if (query.isEmpty) {
      clearSearch();
      return;
    }

    _isLoading = true;
    _error = null;
    _isSearchMode = true;
    notifyListeners();

    try {
      // Try Supabase full-text search first
      List<BibleVerse> results = await _searchFromSupabase(query);
      if (results.isEmpty) {
        results = await _searchFromLocal(query);
      }
      _searchResults = results;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error searching verses: $e');
      try {
        _searchResults = await _searchFromLocal(query);
      } catch (_) {}
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<BibleVerse>> _searchFromSupabase(String query) async {
    try {
      final data = await _supabaseService.searchBibleVerses(query);
      return data.map((e) => BibleVerse(
        id: (e['id'] as num?)?.toInt() ?? 0,
        book: e['book'] as String,
        chapter: (e['chapter'] as num).toInt(),
        verse: (e['verse'] as num).toInt(),
        text: e['text'] as String,
      )).toList();
    } catch (e) {
      debugPrint('Supabase bible search failed: $e');
      return [];
    }
  }

  Future<List<BibleVerse>> _searchFromLocal(String query) async {
    try {
      return await _bibleService.searchVerses(query);
    } catch (e) {
      debugPrint('Local bible search failed: $e');
      return [];
    }
  }

  void clearSearch() {
    _isSearchMode = false;
    _searchResults = [];
    _error = null;
    notifyListeners();
  }
}

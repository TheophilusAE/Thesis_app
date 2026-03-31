import 'package:flutter/material.dart';

import '../models/bible_verse.dart';
import '../services/bible_service.dart';

class RemakeBibleScreen extends StatefulWidget {
  const RemakeBibleScreen({super.key});

  @override
  State<RemakeBibleScreen> createState() => _RemakeBibleScreenState();
}

class _RemakeBibleScreenState extends State<RemakeBibleScreen> {
  final BibleService _service = BibleService();
  final TextEditingController _searchController = TextEditingController();

  late final List<BibleBook> _books;
  BibleBook? _selectedBook;
  int _selectedChapter = 1;

  bool _isLoading = false;
  String? _error;
  List<BibleVerse> _verses = [];

  @override
  void initState() {
    super.initState();
    _books = _service.getBibleBooks();
    if (_books.isNotEmpty) {
      _selectedBook = _books.first;
      _loadChapter();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChapter() async {
    final book = _selectedBook;
    if (book == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final verses = await _service.getVersesByBook(book.name, _selectedChapter);
      setState(() {
        _verses = verses;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      _loadChapter();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final verses = await _service.searchVerses(query);
      setState(() {
        _verses = verses;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<BibleBook>(
                  initialValue: _selectedBook,
                  decoration: const InputDecoration(labelText: 'Book'),
                  items: _books
                      .map(
                        (book) => DropdownMenuItem<BibleBook>(
                          value: book,
                          child: Text(book.name),
                        ),
                      )
                      .toList(),
                  onChanged: (book) {
                    if (book == null) {
                      return;
                    }

                    setState(() {
                      _selectedBook = book;
                      _selectedChapter = 1;
                    });
                    _loadChapter();
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedChapter,
                  decoration: const InputDecoration(labelText: 'Chapter'),
                  items: _selectedBook == null
                      ? const []
                      : List.generate(
                          _selectedBook!.chapters,
                          (i) => DropdownMenuItem<int>(
                            value: i + 1,
                            child: Text('${i + 1}'),
                          ),
                        ),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedChapter = value;
                    });
                    _loadChapter();
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search verse text',
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _search,
                child: const Text('Search'),
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!),
              ),
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _verses.isEmpty
                  ? const Center(child: Text('No verses found.'))
                  : ListView.separated(
                      itemCount: _verses.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final verse = _verses[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 16,
                            child: Text('${verse.verse}'),
                          ),
                          title: Text(
                            verse.text,
                            style: const TextStyle(height: 1.4),
                          ),
                          subtitle: Text('${verse.book} ${verse.chapter}:${verse.verse}'),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

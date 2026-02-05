import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../models/bible_verse.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({Key? key}) : super(key: key);

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final TextEditingController _searchController = TextEditingController();
  BibleBook? _selectedBook;
  int _selectedChapter = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alkitab Offline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: BibleSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: Consumer<BibleProvider>(
        builder: (context, bibleProvider, child) {
          return Column(
            children: [
              // Book and Chapter Selector
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<BibleBook>(
                            decoration: const InputDecoration(
                              labelText: 'Pilih Kitab',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            value: _selectedBook,
                            items: bibleProvider.books.map((book) {
                              return DropdownMenuItem(
                                value: book,
                                child: Text(book.name),
                              );
                            }).toList(),
                            onChanged: (book) {
                              setState(() {
                                _selectedBook = book;
                                _selectedChapter = 1;
                              });
                              if (book != null) {
                                bibleProvider.loadChapter(book.name, 1);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Pasal',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            value: _selectedChapter,
                            items: _selectedBook != null
                                ? List.generate(_selectedBook!.chapters, (i) => i + 1)
                                    .map((chapter) {
                                    return DropdownMenuItem(
                                      value: chapter,
                                      child: Text('$chapter'),
                                    );
                                  }).toList()
                                : [
                                    const DropdownMenuItem(value: 1, child: Text('1')),
                                  ],
                            onChanged: _selectedBook != null
                                ? (chapter) {
                                    setState(() {
                                      _selectedChapter = chapter!;
                                    });
                                    bibleProvider.loadChapter(
                                      _selectedBook!.name,
                                      chapter!,
                                    );
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Verses Display
              Expanded(
                child: bibleProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : bibleProvider.error != null
                        ? Center(child: Text('Error: ${bibleProvider.error}'))
                        : bibleProvider.verses.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.book, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'Pilih kitab untuk memulai',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: bibleProvider.verses.length,
                                itemBuilder: (context, index) {
                                  final verse = bibleProvider.verses[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${verse.verse}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            verse.text,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class BibleSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final bibleProvider = Provider.of<BibleProvider>(context, listen: false);
    bibleProvider.searchVerses(query);

    return Consumer<BibleProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.verses.isEmpty) {
          return const Center(child: Text('Tidak ada ayat ditemukan'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.verses.length,
          itemBuilder: (context, index) {
            final verse = provider.verses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${verse.book} ${verse.chapter}:${verse.verse}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(verse.text),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Ketik untuk mencari ayat',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

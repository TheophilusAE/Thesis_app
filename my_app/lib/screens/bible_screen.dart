import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../models/bible_verse.dart';
import '../utils/app_theme.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final TextEditingController _searchController = TextEditingController();
  BibleBook? _selectedBook;
  int _selectedChapter = 1;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Load the last saved position after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBibleScreen();
    });
  }

  Future<void> _initializeBibleScreen() async {
    if (_initialized) return;

    final bibleProvider = context.read<BibleProvider>();
    await bibleProvider.ensureInitialized();

    final lastBook = bibleProvider.lastBook;
    final lastChapter = bibleProvider.lastChapter;

    // Find the book object
    final book = bibleProvider.books.firstWhere(
      (b) => b.name == lastBook,
      orElse: () => bibleProvider.books.first,
    );

    setState(() {
      _selectedBook = book;
      _selectedChapter = lastChapter;
      _initialized = true;
    });

    // Load the verses
    await bibleProvider.loadChapter(book.name, lastChapter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryTextColor = colorScheme.onSurface.withValues(alpha: 0.72);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alkitab'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: BibleSearchDelegate());
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
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.blueGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A5F).withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                        final useVerticalLayout = constraints.maxWidth < 430 || textScale > 1.15;

                        final labelStyle = TextStyle(
                          color: colorScheme.onPrimary.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        );

                        final bookSelector = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pilih Kitab', style: labelStyle),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<BibleBook>(
                              decoration: InputDecoration(
                                hintText: 'Pilih Kitab',
                                prefixIcon: Icon(
                                  Icons.book,
                                  color: secondaryTextColor,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 18,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.95),
                              ),
                              initialValue: _selectedBook,
                              isExpanded: true,
                              menuMaxHeight: 420,
                              items: bibleProvider.books.map((book) {
                                return DropdownMenuItem(
                                  value: book,
                                  child: Text(
                                    book.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                          ],
                        );

                        final chapterSelector = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pasal', style: labelStyle),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                hintText: 'Pilih Pasal',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 18,
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.95),
                              ),
                              initialValue: _selectedChapter,
                              isExpanded: true,
                              menuMaxHeight: 420,
                              items: _selectedBook != null
                                  ? List.generate(
                                      _selectedBook!.chapters,
                                      (i) => i + 1,
                                    ).map((chapter) {
                                      return DropdownMenuItem(
                                        value: chapter,
                                        child: Text('$chapter'),
                                      );
                                    }).toList()
                                  : [
                                      const DropdownMenuItem(
                                        value: 1,
                                        child: Text('1'),
                                      ),
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
                          ],
                        );

                        if (useVerticalLayout) {
                          return Column(
                            children: [
                              bookSelector,
                              const SizedBox(height: 14),
                              chapterSelector,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: bookSelector),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 136,
                              child: chapterSelector,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Verses Display
              Expanded(
                child: bibleProvider.isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Memuat ayat offline...'),
                          ],
                        ),
                      )
                    : bibleProvider.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Gagal Mengambil Ayat',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                bibleProvider.error ?? 'Terjadi kesalahan saat memuat data lokal',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_selectedBook != null)
                              ElevatedButton.icon(
                                onPressed: () {
                                  bibleProvider.loadChapter(
                                    _selectedBook!.name,
                                    _selectedChapter,
                                  );
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba Lagi'),
                              ),
                          ],
                        ),
                      )
                    : bibleProvider.verses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book,
                              size: 64,
                              color: secondaryTextColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Pilih kitab untuk memulai',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 16,
                              ),
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
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.purpleBlueGradient,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${verse.verse}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        verse.text,
                                        maxLines: 10,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.6,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
  String _lastSearchedQuery = '';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          context.read<BibleProvider>().clearSearch();
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        context.read<BibleProvider>().clearSearch();
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryTextColor = colorScheme.onSurface.withValues(alpha: 0.72);

    if (query.trim().isEmpty) {
      context.read<BibleProvider>().clearSearch();
      return buildSuggestions(context);
    }

    if (_lastSearchedQuery != query) {
      _lastSearchedQuery = query;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<BibleProvider>().searchVerses(query);
        }
      });
    }

    return Consumer<BibleProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.verses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: secondaryTextColor),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada ayat ditemukan',
                  style: TextStyle(color: secondaryTextColor, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.verses.length,
          itemBuilder: (context, index) {
            final verse = provider.verses[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF74BB96),
                                  const Color(0xFF1E3A5F),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${verse.book} ${verse.chapter}:${verse.verse}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        verse.text,
                        maxLines: 8,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryTextColor = colorScheme.onSurface.withValues(alpha: 0.72);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: secondaryTextColor),
          const SizedBox(height: 16),
          Text(
            'Ketik untuk mencari ayat',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contoh: "kasih", "iman", "harapan"',
            style: TextStyle(color: secondaryTextColor, fontSize: 13),
          ),
        ],
      ),
    );
  }
}


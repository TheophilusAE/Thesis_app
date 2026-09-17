import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bible_verse.dart';
import '../providers/bible_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_error_state.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  BibleBook? _selectedBook;
  int _selectedChapter = 1;
  bool _initialized = false;
  double _fontSize = 17.0;

  @override
  void initState() {
    super.initState();
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

    final book = bibleProvider.books.firstWhere(
      (b) => b.name == lastBook,
      orElse: () => bibleProvider.books.isNotEmpty ? bibleProvider.books.first : BibleBook(name: 'Kejadian', chapters: 50),
    );

    setState(() {
      _selectedBook = book;
      _selectedChapter = lastChapter;
      _initialized = true;
    });

    await bibleProvider.loadChapter(book.name, lastChapter);
  }

  void _nextChapter() {
    if (_selectedBook == null) return;
    if (_selectedChapter < _selectedBook!.chapters) {
      _changeChapter(_selectedChapter + 1);
    } else {
      // Advance to next book if available
      final books = context.read<BibleProvider>().books;
      final curIdx = books.indexOf(_selectedBook!);
      if (curIdx >= 0 && curIdx < books.length - 1) {
        final nextBook = books[curIdx + 1];
        setState(() {
          _selectedBook = nextBook;
          _selectedChapter = 1;
        });
        context.read<BibleProvider>().loadChapter(nextBook.name, 1);
        _scrollToTop();
      }
    }
  }

  void _prevChapter() {
    if (_selectedBook == null) return;
    if (_selectedChapter > 1) {
      _changeChapter(_selectedChapter - 1);
    } else {
      // Go to previous book's last chapter
      final books = context.read<BibleProvider>().books;
      final curIdx = books.indexOf(_selectedBook!);
      if (curIdx > 0) {
        final prevBook = books[curIdx - 1];
        setState(() {
          _selectedBook = prevBook;
          _selectedChapter = prevBook.chapters;
        });
        context.read<BibleProvider>().loadChapter(prevBook.name, prevBook.chapters);
        _scrollToTop();
      }
    }
  }

  void _changeChapter(int chapter) {
    if (_selectedBook == null) return;
    setState(() => _selectedChapter = chapter);
    context.read<BibleProvider>().loadChapter(_selectedBook!.name, chapter);
    _scrollToTop();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showBookChapterModal(BuildContext context, BibleProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final theme = Theme.of(modalContext);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          height: MediaQuery.of(modalContext).size.height * 0.78,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1C1F) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3E3B40) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pilih Kitab & Pasal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFF5F3F6) : AppTheme.textColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  indicatorColor: AppTheme.primary,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.mutedText,
                  tabs: [
                    Tab(text: 'Daftar Kitab'),
                    Tab(text: 'Pilih Pasal'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Books List
                      ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: provider.books.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final book = provider.books[i];
                          final isCurrent = book.name == _selectedBook?.name;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isCurrent ? AppTheme.primary : AppTheme.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: isCurrent ? Colors.white : AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            title: Text(
                              book.name,
                              style: TextStyle(
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                color: isCurrent ? AppTheme.primary : (isDark ? Colors.white : AppTheme.textColor),
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text('${book.chapters} Pasal'),
                            trailing: isCurrent ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary) : null,
                            onTap: () {
                              setState(() {
                                _selectedBook = book;
                                _selectedChapter = 1;
                              });
                              provider.loadChapter(book.name, 1);
                              Navigator.pop(modalContext);
                            },
                          );
                        },
                      ),
                      // Tab 2: Chapters Grid for selected book
                      if (_selectedBook != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_selectedBook!.name} — ${_selectedBook!.chapters} Pasal',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              const SizedBox(height: 14),
                              Expanded(
                                child: GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                                  itemCount: _selectedBook!.chapters,
                                  itemBuilder: (_, idx) {
                                    final ch = idx + 1;
                                    final isCur = ch == _selectedChapter;
                                    return Material(
                                      color: isCur ? AppTheme.primary : (isDark ? const Color(0xFF2E2B30) : const Color(0xFFF5F5F5)),
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        onTap: () {
                                          _changeChapter(ch);
                                          Navigator.pop(modalContext);
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Center(
                                          child: Text(
                                            '$ch',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              color: isCur ? Colors.white : (isDark ? Colors.white : AppTheme.textColor),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Center(child: Text('Pilih kitab terlebih dahulu')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141214) : AppTheme.background,
      appBar: AppBar(
        title: const Text('Alkitab'),
        actions: [
          // Text size adjuster
          PopupMenuButton<double>(
            icon: const Icon(Icons.format_size_rounded),
            tooltip: 'Ukuran Huruf',
            onSelected: (size) => setState(() => _fontSize = size),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 15.0, child: Text('Ukuran Normal (15sp)')),
              const PopupMenuItem(value: 17.0, child: Text('Ukuran Nyaman (17sp)')),
              const PopupMenuItem(value: 20.0, child: Text('Ukuran Besar (20sp)')),
              const PopupMenuItem(value: 24.0, child: Text('Ukuran Sangat Besar (24sp)')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Cari Ayat',
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
              // Modern, calm Book & Chapter selector strip
              Container(
                margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1C1F) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2E2B30) : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    // Previous chapter button
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      tooltip: 'Pasal Sebelumnya',
                      onPressed: _prevChapter,
                      color: AppTheme.primary,
                    ),
                    // Tap to open book & chapter modal
                    Expanded(
                      child: InkWell(
                        onTap: () => _showBookChapterModal(context, bibleProvider),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  '${_selectedBook?.name ?? 'Pilih Kitab'} $_selectedChapter',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFFF5F3F6) : AppTheme.textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primary, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Next chapter button
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 28),
                      tooltip: 'Pasal Berikutnya',
                      onPressed: _nextChapter,
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              ),

              // Verses Reader Content
              Expanded(
                child: bibleProvider.isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppTheme.primary),
                            SizedBox(height: 16),
                            Text(
                              'Memuat ayat offline...',
                              style: TextStyle(color: AppTheme.secondaryText, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : bibleProvider.error != null
                        ? AppErrorState(
                            error: bibleProvider.error,
                            onRetry: _selectedBook != null
                                ? () => bibleProvider.loadChapter(_selectedBook!.name, _selectedChapter)
                                : null,
                          )
                        : bibleProvider.verses.isEmpty
                            ? AppEmptyState(
                                icon: Icons.menu_book_rounded,
                                title: 'Pilih Kitab untuk Membaca',
                                message: 'Gunakan pemilih kitab di atas untuk mulai membaca firman Tuhan.',
                                actionLabel: 'Buka Daftar Kitab',
                                onAction: () => _showBookChapterModal(context, bibleProvider),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                                itemCount: bibleProvider.verses.length + 1,
                                itemBuilder: (context, index) {
                                  // Chapter Footer Navigation Card
                                  if (index == bibleProvider.verses.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 28, bottom: 20),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: _prevChapter,
                                              icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                              label: const Text('Sebelumnya'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppTheme.primary,
                                                side: const BorderSide(color: Color(0xFFE5E7EB)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: _nextChapter,
                                              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                                              label: const Text('Berikutnya'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.primary,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final verse = bibleProvider.verses[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Verse Number badge
                                        Container(
                                          width: 32,
                                          height: 32,
                                          alignment: Alignment.center,
                                          margin: const EdgeInsets.only(top: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF2A1519) : AppTheme.primaryLight,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${verse.verse}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.primary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        // Verse Text with readable line-height
                                        Expanded(
                                          child: Text(
                                            verse.text,
                                            style: TextStyle(
                                              fontSize: _fontSize,
                                              height: 1.65,
                                              fontWeight: FontWeight.w400,
                                              color: isDark ? const Color(0xFFE8E6EB) : const Color(0xFF222222),
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
  String _lastSearchedQuery = '';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear_rounded),
        tooltip: 'Hapus Pencarian',
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
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      tooltip: 'Kembali',
      onPressed: () {
        context.read<BibleProvider>().clearSearch();
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (provider.verses.isEmpty) {
          return AppEmptyState(
            icon: Icons.search_off_rounded,
            title: 'Ayat Tidak Ditemukan',
            message: 'Tidak ada ayat Alkitab yang cocok dengan kata "$query". Coba kata kunci lain.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.verses.length,
          itemBuilder: (context, index) {
            final verse = provider.verses[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${verse.book} ${verse.chapter}:${verse.verse}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      verse.text,
                      style: TextStyle(
                        fontSize: 15.5,
                        height: 1.6,
                        color: isDark ? const Color(0xFFF5F3F6) : AppTheme.textColor,
                      ),
                    ),
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
    return AppEmptyState(
      icon: Icons.search_rounded,
      title: 'Pencarian Alkitab',
      message: 'Ketik kata atau frasa untuk mencari ayat.\nContoh: "kasih", "iman", "gembala", "damai".',
    );
  }
}

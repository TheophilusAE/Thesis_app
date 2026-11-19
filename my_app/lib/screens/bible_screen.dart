import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bible_verse.dart';
import '../providers/bible_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/app_empty_state.dart';
import '../widgets/common/app_error_state.dart';
import '../widgets/bible_reference_picker.dart';

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
  int? _highlightVerse;
  final Map<int, GlobalKey> _verseKeys = {};

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
    setState(() {
      _selectedChapter = chapter;
      _highlightVerse = null;
    });
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

  /// Kitab -> Pasal -> Ayat picker; jumps to the chosen verse.
  Future<void> _openPicker(BibleProvider provider) async {
    final ref = await showBibleReferencePicker(
      context,
      books: provider.books,
      verseCount: provider.verseCount,
      currentBook: _selectedBook,
      currentChapter: _selectedChapter,
    );
    if (ref == null || !mounted) return;
    setState(() {
      _selectedBook = ref.book;
      _selectedChapter = ref.chapter;
      _highlightVerse = ref.verse;
    });
    await provider.loadChapter(ref.book.name, ref.chapter);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = ref.verse == null ? null : _verseKeys[ref.verse]?.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 350), alignment: 0.1);
      } else if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
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
          // Text size: A- / A+ (saved on the device)
          Consumer<BibleProvider>(
            builder: (context, bible, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Perkecil huruf',
                  onPressed: bible.canDecreaseFont ? bible.decreaseFont : null,
                  icon: const Text('A−', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: 'Perbesar huruf',
                  onPressed: bible.canIncreaseFont ? bible.increaseFont : null,
                  icon: const Text('A+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
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
                        onTap: () => _openPicker(bibleProvider),
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
                              Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primary, size: 22),
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
                    ? Center(
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
                                onAction: () => _openPicker(bibleProvider),
                              )
                            : SingleChildScrollView(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                                child: Column(
                                  children: [
                                    for (final verse in bibleProvider.verses)
                                      _VerseRow(
                                        key: _verseKeys.putIfAbsent(verse.verse, () => GlobalKey()),
                                        number: verse.verse,
                                        text: verse.text,
                                        fontSize: bibleProvider.fontSize,
                                        highlighted: verse.verse == _highlightVerse,
                                      ),
                                    Padding(
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
                                    ),
                                  ],
                                ),
                              ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One verse: number badge + text; tinted when jumped to from the picker.
class _VerseRow extends StatelessWidget {
  final int number;
  final String text;
  final double fontSize;
  final bool highlighted;

  const _VerseRow({
    super.key,
    required this.number,
    required this.text,
    required this.fontSize,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: highlighted ? AppTheme.goldDark.withValues(alpha: isDark ? 0.25 : 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              '$number',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.65,
                color: isDark ? const Color(0xFFE8E6EB) : const Color(0xFF222222),
              ),
            ),
          ),
        ],
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
          return Center(
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
                            style: TextStyle(
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

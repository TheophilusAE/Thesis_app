import 'package:flutter/material.dart';

import '../models/bible_verse.dart';

/// A place in the Bible chosen in [BibleReferencePicker]. [verse] is null
/// when the reader chose to start at the top of the chapter.
class BibleReference {
  final BibleBook book;
  final int chapter;
  final int? verse;

  const BibleReference(this.book, this.chapter, [this.verse]);
}

/// Opens the picker as a tall bottom sheet: Kitab → Pasal → Ayat.
Future<BibleReference?> showBibleReferencePicker(
  BuildContext context, {
  required List<BibleBook> books,
  required Future<int> Function(String book, int chapter) verseCount,
  BibleBook? currentBook,
  int? currentChapter,
}) {
  return showModalBottomSheet<BibleReference>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.85,
      child: BibleReferencePicker(
        books: books,
        verseCount: verseCount,
        currentBook: currentBook,
        currentChapter: currentChapter,
        onSelected: (ref) => Navigator.pop(ctx, ref),
        onClose: () => Navigator.pop(ctx),
      ),
    ),
  );
}

enum _Step { book, chapter, verse }

class BibleReferencePicker extends StatefulWidget {
  final List<BibleBook> books;
  final Future<int> Function(String book, int chapter) verseCount;
  final BibleBook? currentBook;
  final int? currentChapter;
  final ValueChanged<BibleReference> onSelected;
  final VoidCallback onClose;

  const BibleReferencePicker({
    super.key,
    required this.books,
    required this.verseCount,
    required this.onSelected,
    required this.onClose,
    this.currentBook,
    this.currentChapter,
  });

  @override
  State<BibleReferencePicker> createState() => _BibleReferencePickerState();
}

class _BibleReferencePickerState extends State<BibleReferencePicker> {
  _Step _step = _Step.book;
  BibleBook? _book;
  int? _chapter;
  Future<int>? _verses;
  String _filter = '';

  void _pickBook(BibleBook b) => setState(() {
        _book = b;
        _chapter = null;
        _step = _Step.chapter;
      });

  void _pickChapter(int c) => setState(() {
        _chapter = c;
        _verses = widget.verseCount(_book!.name, c);
        _step = _Step.verse;
      });

  void _back() => setState(() {
        _step = _step == _Step.verse ? _Step.chapter : _Step.book;
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = switch (_step) {
      _Step.book => 'Pilih Kitab',
      _Step.chapter => _book!.name,
      _Step.verse => '${_book!.name} $_chapter',
    };
    final hint = switch (_step) {
      _Step.book => null,
      _Step.chapter => 'Pilih pasal',
      _Step.verse => 'Pilih ayat',
    };

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Row(
              children: [
                if (_step != _Step.book)
                  IconButton(tooltip: 'Kembali', icon: const Icon(Icons.arrow_back_rounded), onPressed: _back)
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Column(
                    children: [
                      Text(title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      if (hint != null) Text(hint, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(tooltip: 'Tutup', icon: const Icon(Icons.close_rounded), onPressed: widget.onClose),
              ],
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: switch (_step) {
              _Step.book => _bookList(theme),
              _Step.chapter => _numberGrid(
                  count: _book!.chapters,
                  current: _book!.name == widget.currentBook?.name ? widget.currentChapter : null,
                  onTap: _pickChapter,
                ),
              _Step.verse => FutureBuilder<int>(
                  future: _verses,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final n = snap.data ?? 0;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.vertical_align_top_rounded),
                              label: const Text('Baca dari awal pasal'),
                              onPressed: () => widget.onSelected(BibleReference(_book!, _chapter!)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: n == 0
                              ? const Center(child: Text('Ayat untuk pasal ini belum tersedia.'))
                              : _numberGrid(
                                  count: n,
                                  onTap: (v) => widget.onSelected(BibleReference(_book!, _chapter!, v)),
                                ),
                        ),
                      ],
                    );
                  },
                ),
            },
          ),
        ],
      ),
    );
  }

  Widget _bookList(ThemeData theme) {
    final q = _filter.trim().toLowerCase();
    final indexed = [
      for (var i = 0; i < widget.books.length; i++)
        if (q.isEmpty || widget.books[i].name.toLowerCase().contains(q)) (i, widget.books[i]),
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Cari kitab',
              isDense: true,
            ),
            onChanged: (v) => setState(() => _filter = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: indexed.length,
            itemBuilder: (_, k) {
              final (i, book) = indexed[k];
              final isCurrent = book.name == widget.currentBook?.name;
              // Heading before the first book of each testament (39 PL books).
              final heading = q.isEmpty && (i == 0 || i == 39)
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Text(i == 0 ? 'Perjanjian Lama' : 'Perjanjian Baru',
                          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                    )
                  : null;
              final tile = ListTile(
                dense: true,
                title: Text(
                  book.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent ? theme.colorScheme.primary : null,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _pickBook(book),
              );
              return heading == null ? tile : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [heading, tile]);
            },
          ),
        ),
      ],
    );
  }

  Widget _numberGrid({required int count, required ValueChanged<int> onTap, int? current}) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 64,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: count,
      itemBuilder: (_, i) {
        final n = i + 1;
        final selected = n == current;
        return Material(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onTap(n),
            child: Center(
              child: Text(
                '$n',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

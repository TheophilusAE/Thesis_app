import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bible_verse.dart';
import '../models/reading_quest.dart';
import '../providers/bible_provider.dart';
import '../providers/quest_provider.dart';
import '../services/bible_service.dart';
import '../utils/app_theme.dart';
import '../utils/reading_validator.dart';

typedef ChapterLoader = Future<List<BibleVerse>> Function(String book, int chapter);

/// One chapter of a day's reading, split into sections (blocks of verses)
/// that each have to be on screen for a moment.
class _ChapterBlock {
  final String book;
  final int chapter;
  final List<List<BibleVerse>> sections;
  _ChapterBlock(this.book, this.chapter, this.sections);
}

/// Quest Baca: shows the day's passage and unlocks "Selesai Membaca" only
/// after real reading (time + scroll + every section seen), see
/// [ReadingValidator].
class QuestReadingScreen extends StatefulWidget {
  final ReadingQuest quest;
  final ChapterLoader? loadChapter;

  const QuestReadingScreen({super.key, required this.quest, this.loadChapter});

  /// Verses per section; a section must be on screen ≥ 2 s.
  static const int versesPerSection = 8;

  @override
  State<QuestReadingScreen> createState() => _QuestReadingScreenState();
}

class _QuestReadingScreenState extends State<QuestReadingScreen> with WidgetsBindingObserver {
  final _scroll = ScrollController();
  final _viewportKey = GlobalKey();
  final List<GlobalKey> _sectionKeys = [];
  List<_ChapterBlock> _blocks = [];
  ReadingValidator? _validator;
  Timer? _timer;
  bool _active = true;
  bool _loading = true;
  String? _error;
  bool _saving = false;
  bool _celebrate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Time only counts while the app is in front of the reader.
    _active = state == AppLifecycleState.resumed;
  }

  Future<void> _load() async {
    final loader = widget.loadChapter ?? BibleService().getVersesByBook;
    try {
      final blocks = <_ChapterBlock>[];
      for (final r in widget.quest.readings) {
        final book = BibleProvider.renamedBooks[r.book] ?? r.book;
        for (var c = r.startChapter; c <= r.endChapter; c++) {
          final verses = await loader(book, c);
          if (verses.isEmpty) continue;
          final sections = <List<BibleVerse>>[];
          for (var i = 0; i < verses.length; i += QuestReadingScreen.versesPerSection) {
            final end = i + QuestReadingScreen.versesPerSection;
            sections.add(verses.sublist(i, end > verses.length ? verses.length : end));
          }
          blocks.add(_ChapterBlock(book, c, sections));
        }
      }
      if (!mounted) return;
      if (blocks.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Teks bacaan belum tersedia di perangkat ini.';
        });
        return;
      }
      final words = blocks
          .expand((b) => b.sections)
          .expand((s) => s)
          .fold<int>(0, (n, v) => n + ReadingValidator.countWords(v.text));
      final sectionCount = blocks.fold<int>(0, (n, b) => n + b.sections.length);
      _sectionKeys
        ..clear()
        ..addAll(List.generate(sectionCount, (_) => GlobalKey()));
      setState(() {
        _blocks = blocks;
        _validator = ReadingValidator(wordCount: words, sectionCount: sectionCount);
        _loading = false;
      });
      if (!widget.quest.isCompleted) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
        WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Teks bacaan gagal dimuat.';
      });
    }
  }

  void _onScroll() {
    final v = _validator;
    if (v == null || !_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    v.updateScroll(max <= 0 ? 1.0 : _scroll.position.pixels / max);
  }

  /// Sections at least half visible (or filling half the screen).
  Set<int> _visibleSections() {
    final viewport = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.hasSize) return const {};
    final vTop = viewport.localToGlobal(Offset.zero).dy;
    final vBottom = vTop + viewport.size.height;
    final visible = <int>{};
    for (var i = 0; i < _sectionKeys.length; i++) {
      final box = _sectionKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize || !box.attached) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      final overlap = (bottom < vBottom ? bottom : vBottom) - (top > vTop ? top : vTop);
      if (overlap <= 0) continue;
      final need = (box.size.height < viewport.size.height ? box.size.height : viewport.size.height) * 0.5;
      if (overlap >= need) visible.add(i);
    }
    return visible;
  }

  void _tick() {
    final v = _validator;
    if (v == null || !_active || !mounted) return;
    final wasOk = v.isSatisfied;
    v.tick(const Duration(seconds: 1), _visibleSections());
    _onScroll();
    if (!wasOk || !v.isSatisfied) setState(() {});
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final saved = await context.read<QuestProvider>().markDayCompleted(widget.quest.day);
    if (!mounted) return;
    if (!saved) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login untuk menyimpan progres bacaan.')),
      );
      return;
    }
    _timer?.cancel();
    setState(() => _celebrate = true);
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (mounted) Navigator.of(context).pop(true);
  }

  String _fmt(num seconds) {
    final s = seconds.round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontSize = context.watch<BibleProvider>().fontSize;
    final v = _validator;
    final done = widget.quest.isCompleted;
    final title = widget.quest.readings.map((r) => r.displayText).join(', ');

    var sectionIndex = 0;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hari ${widget.quest.day}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: done ? 1 : (v?.progress ?? 0),
            minHeight: 4,
            color: AppTheme.emerald,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
                  : SingleChildScrollView(
                      key: _viewportKey,
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            done
                                ? 'Bacaan hari ini sudah selesai.'
                                : 'Baca sampai akhir. Tombol selesai aktif setelah waktu baca minimal tercapai.',
                            style: theme.textTheme.bodySmall,
                          ),
                          for (final block in _blocks) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 24, bottom: 8),
                              child: Text('${block.book} ${block.chapter}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                            ),
                            for (final section in block.sections)
                              Container(
                                key: _sectionKeys[sectionIndex++],
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final verse in section)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Text.rich(
                                          TextSpan(children: [
                                            TextSpan(
                                              text: '${verse.verse} ',
                                              style: TextStyle(
                                                fontSize: fontSize * 0.7,
                                                fontWeight: FontWeight.w700,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                            TextSpan(text: verse.text),
                                          ]),
                                          style: TextStyle(fontSize: fontSize, height: 1.6),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
          if (_celebrate) const _Celebration(),
        ],
      ),
      bottomNavigationBar: _loading || _error != null || done
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (v != null && !v.isSatisfied)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Wrap(
                          spacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            _Check(ok: v.timeOk, label: 'Waktu ${_fmt(v.elapsedSeconds.clamp(0, v.requiredSeconds))}/${_fmt(v.requiredSeconds)}'),
                            _Check(ok: v.scrollOk, label: 'Sampai akhir'),
                            _Check(ok: v.sectionsOk, label: 'Bagian ${v.sectionsRead}/${v.sectionCount}'),
                          ],
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: v != null && v.isSatisfied && !_saving && !_celebrate ? _finish : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.emerald,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_rounded),
                        label: const Text('Selesai Membaca'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Check extends StatelessWidget {
  final bool ok;
  final String label;
  const _Check({required this.ok, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppTheme.emerald : Theme.of(context).textTheme.bodySmall?.color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

/// Completion animation: a check that pops in over a dimmed screen.
class _Celebration extends StatelessWidget {
  const _Celebration();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, t, child) => Transform.scale(scale: t, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: AppTheme.emerald, size: 72),
                  SizedBox(height: 12),
                  Text('Puji Tuhan!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Bacaan hari ini selesai.'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

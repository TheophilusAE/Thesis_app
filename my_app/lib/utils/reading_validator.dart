/// Decides when a Quest Baca reading may be marked "selesai".
///
/// Three conditions, all required (no network, no server — progress is
/// still stored per account on the device):
///  1. **Time**: active reading time (app in the foreground, screen open)
///     of at least 40% of the estimated reading time at 200 words/minute,
///     clamped to [minSeconds]–[maxSeconds].
///  2. **Scroll**: the reader reached [requiredScroll] of the passage.
///  3. **Sections**: every section (a block of verses) was on screen for at
///     least [sectionSeconds] in total, so jumping straight to the end
///     doesn't count.
class ReadingValidator {
  ReadingValidator({required this.wordCount, required this.sectionCount})
      : requiredSeconds = estimateRequiredSeconds(wordCount),
        _sectionTime = List<double>.filled(sectionCount, 0);

  static const int wordsPerMinute = 200;
  static const double readFraction = 0.4;
  static const int minSeconds = 15;
  static const int maxSeconds = 180;
  static const double requiredScroll = 0.95;
  static const double sectionSeconds = 2;

  final int wordCount;
  final int sectionCount;
  final int requiredSeconds;
  final List<double> _sectionTime;

  double _elapsed = 0;
  double _maxScroll = 0;

  static int estimateRequiredSeconds(int words) {
    final full = words / wordsPerMinute * 60;
    return (full * readFraction).round().clamp(minSeconds, maxSeconds);
  }

  static int countWords(String text) =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  /// Adds active reading time; [visibleSections] are the sections on screen
  /// during that time.
  void tick(Duration dt, Iterable<int> visibleSections) {
    final s = dt.inMilliseconds / 1000;
    if (s <= 0) return;
    _elapsed += s;
    for (final i in visibleSections) {
      if (i >= 0 && i < sectionCount) _sectionTime[i] += s;
    }
  }

  /// [fraction] = scroll offset / max scroll extent (1.0 when the passage
  /// fits on one screen). Only the furthest point counts.
  void updateScroll(double fraction) {
    if (fraction.isNaN) return;
    final f = fraction.clamp(0.0, 1.0);
    if (f > _maxScroll) _maxScroll = f;
  }

  double get elapsedSeconds => _elapsed;
  double get maxScroll => _maxScroll;
  int get sectionsRead => _sectionTime.where((t) => t >= sectionSeconds).length;

  bool get timeOk => _elapsed >= requiredSeconds;
  bool get scrollOk => _maxScroll >= requiredScroll;
  bool get sectionsOk => sectionsRead >= sectionCount;
  bool get isSatisfied => timeOk && scrollOk && sectionsOk;

  /// 0–1 for the progress bar: the weakest of the three conditions, so the
  /// bar is only full when the button unlocks.
  double get progress {
    final t = requiredSeconds == 0 ? 1.0 : (_elapsed / requiredSeconds).clamp(0.0, 1.0);
    final sc = (_maxScroll / requiredScroll).clamp(0.0, 1.0);
    final se = sectionCount == 0 ? 1.0 : sectionsRead / sectionCount;
    return [t, sc, se].reduce((a, b) => a < b ? a : b);
  }

  /// Seconds still needed (0 when the time condition is met).
  int get secondsLeft => (requiredSeconds - _elapsed).ceil().clamp(0, requiredSeconds);
}

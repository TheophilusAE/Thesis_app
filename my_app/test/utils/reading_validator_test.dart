import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_app/models/bible_verse.dart';
import 'package:my_app/models/reading_quest.dart';
import 'package:my_app/providers/bible_provider.dart';
import 'package:my_app/providers/quest_provider.dart';
import 'package:my_app/screens/quest_reading_screen.dart';
import 'package:my_app/utils/reading_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ReadingValidator', () {
    test('required time is 40% of 200 wpm, between 15 s and 3 min', () {
      expect(ReadingValidator.estimateRequiredSeconds(10), 15); // short → minimum
      expect(ReadingValidator.estimateRequiredSeconds(1000), 120); // 300 s × 0.4
      expect(ReadingValidator.estimateRequiredSeconds(5000), 180); // long → maximum
    });

    test('jumping to the end without reading does not unlock', () {
      final v = ReadingValidator(wordCount: 1000, sectionCount: 3);
      v.updateScroll(1.0);
      expect(v.scrollOk, isTrue);
      expect(v.isSatisfied, isFalse);

      // Time passes while only the last section is on screen.
      for (var i = 0; i < 200; i++) {
        v.tick(const Duration(seconds: 1), {2});
      }
      expect(v.timeOk, isTrue);
      expect(v.sectionsOk, isFalse);
      expect(v.isSatisfied, isFalse);
    });

    test('reading every section for long enough, to the end, unlocks', () {
      final v = ReadingValidator(wordCount: 100, sectionCount: 3); // needs 15 s
      for (final s in [0, 1, 2]) {
        for (var i = 0; i < 5; i++) {
          v.tick(const Duration(seconds: 1), {s});
        }
        v.updateScroll((s + 1) / 3);
      }
      expect(v.elapsedSeconds, 15);
      expect(v.sectionsRead, 3);
      expect(v.isSatisfied, isTrue);
      expect(v.progress, 1);
    });

    test('progress follows the weakest condition and scroll never goes back', () {
      final v = ReadingValidator(wordCount: 100, sectionCount: 2);
      v.updateScroll(0.8);
      v.updateScroll(0.2);
      expect(v.maxScroll, 0.8);
      v.tick(const Duration(seconds: 15), {0, 1});
      expect(v.timeOk, isTrue);
      expect(v.sectionsOk, isTrue);
      expect(v.progress, closeTo(0.8 / 0.95, 0.001));
    });
  });

  group('QuestReadingScreen', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    List<BibleVerse> verses(String book, int chapter, int n) => [
          for (var i = 1; i <= n; i++)
            BibleVerse(id: i, book: book, chapter: chapter, verse: i, text: 'Firman Tuhan ayat $i'),
        ];

    Future<void> pump(WidgetTester tester, ReadingQuest quest, List<String> loaded) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BibleProvider()),
          ChangeNotifierProvider(create: (_) => QuestProvider()),
        ],
        child: MaterialApp(
          home: QuestReadingScreen(
            quest: quest,
            loadChapter: (book, chapter) async {
              loaded.add('$book $chapter');
              return verses(book, chapter, 3);
            },
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('shows the passage with "Selesai Membaca" locked at first', (tester) async {
      final loaded = <String>[];
      await pump(tester, ReadingQuest(day: 7, readings: [ReadingPlan(book: 'Kejadian', startChapter: 1, endChapter: 2)]), loaded);

      expect(loaded, ['Kejadian 1', 'Kejadian 2']);
      expect(find.text('Kejadian 2'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.ancestor(of: find.text('Selesai Membaca'), matching: find.byWidgetPredicate((w) => w is FilledButton)));
      expect(button.onPressed, isNull);
      expect(find.textContaining('Waktu 0:00/0:15'), findsOneWidget);
    });

    testWidgets('the button unlocks after the minimum reading time on a short passage', (tester) async {
      await pump(tester, ReadingQuest(day: 1, readings: [ReadingPlan(book: 'Yudas', startChapter: 1, endChapter: 1)]), []);
      await tester.pump(const Duration(seconds: 16));

      final button = tester.widget<FilledButton>(find.ancestor(of: find.text('Selesai Membaca'), matching: find.byWidgetPredicate((w) => w is FilledButton)));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('old plans with the misspelled "Trenyina" load Ratapan', (tester) async {
      final loaded = <String>[];
      await pump(tester, ReadingQuest(day: 3, readings: [ReadingPlan(book: 'Trenyina', startChapter: 1, endChapter: 1)]), loaded);
      expect(loaded, ['Ratapan 1']);
    });

    testWidgets('a completed day opens read-only without the button', (tester) async {
      await pump(
        tester,
        ReadingQuest(day: 2, readings: [ReadingPlan(book: 'Yudas', startChapter: 1, endChapter: 1)], isCompleted: true),
        [],
      );
      expect(find.text('Selesai Membaca'), findsNothing);
      expect(find.text('Bacaan hari ini sudah selesai.'), findsOneWidget);
    });
  });
}

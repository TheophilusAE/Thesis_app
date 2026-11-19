import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/bible_verse.dart';
import 'package:my_app/services/bible_service.dart';
import 'package:my_app/widgets/bible_reference_picker.dart';

void main() {
  final books = BibleService().getBibleBooks();

  Future<List<BibleReference>> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final picked = <BibleReference>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BibleReferencePicker(
          books: books,
          verseCount: (book, chapter) async => 22,
          onSelected: picked.add,
          onClose: () {},
        ),
      ),
    ));
    return picked;
  }

  test('book 25 is named Ratapan', () {
    expect(books[24].name, 'Ratapan');
    expect(books.map((b) => b.name), isNot(contains('Trenyina')));
  });

  testWidgets('book list shows names only, without "N Pasal"', (tester) async {
    await pump(tester);
    expect(find.text('Kejadian'), findsOneWidget);
    expect(find.textContaining('Pasal'), findsNothing);
  });

  testWidgets('book -> chapter -> verse returns that reference', (tester) async {
    final picked = await pump(tester);

    await tester.enterText(find.byType(TextField), 'ratap');
    await tester.pump();
    await tester.tap(find.text('Ratapan'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih pasal'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('6'), findsNothing); // Ratapan has 5 chapters

    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect(find.text('Ratapan 3'), findsOneWidget);

    await tester.tap(find.text('22'));
    await tester.pump();
    expect(picked.single.book.name, 'Ratapan');
    expect(picked.single.chapter, 3);
    expect(picked.single.verse, 22);
  });

  testWidgets('"Baca dari awal pasal" returns the chapter without a verse', (tester) async {
    final picked = await pump(tester);
    await tester.tap(find.text('Kejadian'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Baca dari awal pasal'));
    await tester.pump();
    expect(picked.single.chapter, 1);
    expect(picked.single.verse, isNull);
  });

  testWidgets('back goes from verses to chapters to books', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Kejadian'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih pasal'), findsOneWidget);
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Kitab'), findsOneWidget);
  });

  test('BibleBook is the shared model', () => expect(books.first, isA<BibleBook>()));
}

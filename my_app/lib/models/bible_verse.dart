class BibleVerse {
  final int id;
  final String book;
  final int chapter;
  final int verse;
  final String text;

  BibleVerse({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      id: json['id'],
      book: json['book'],
      chapter: json['chapter'],
      verse: json['verse'],
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'text': text,
    };
  }
}

class BibleBook {
  final String name;
  final int chapters;

  BibleBook({
    required this.name,
    required this.chapters,
  });
}

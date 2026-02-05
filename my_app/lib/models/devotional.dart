class Devotional {
  final String id;
  final String title;
  final String content;
  final String verse;
  final String verseReference;
  final DateTime date;
  final String? author;

  Devotional({
    required this.id,
    required this.title,
    required this.content,
    required this.verse,
    required this.verseReference,
    required this.date,
    this.author,
  });

  factory Devotional.fromJson(Map<String, dynamic> json) {
    return Devotional(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      verse: json['verse'],
      verseReference: json['verseReference'],
      date: DateTime.parse(json['date']),
      author: json['author'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'verse': verse,
      'verseReference': verseReference,
      'date': date.toIso8601String(),
      'author': author,
    };
  }
}

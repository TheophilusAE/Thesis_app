class ReadingQuest {
  final int day;
  final List<ReadingPlan> readings;
  bool isCompleted;

  ReadingQuest({
    required this.day,
    required this.readings,
    this.isCompleted = false,
  });

  factory ReadingQuest.fromJson(Map<String, dynamic> json) {
    return ReadingQuest(
      day: json['day'],
      readings: (json['readings'] as List)
          .map((r) => ReadingPlan.fromJson(r))
          .toList(),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'readings': readings.map((r) => r.toJson()).toList(),
      'isCompleted': isCompleted,
    };
  }
}

class ReadingPlan {
  final String book;
  final int startChapter;
  final int endChapter;

  ReadingPlan({
    required this.book,
    required this.startChapter,
    required this.endChapter,
  });

  factory ReadingPlan.fromJson(Map<String, dynamic> json) {
    return ReadingPlan(
      book: json['book'],
      startChapter: json['startChapter'],
      endChapter: json['endChapter'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'startChapter': startChapter,
      'endChapter': endChapter,
    };
  }

  String get displayText {
    if (startChapter == endChapter) {
      return '$book $startChapter';
    }
    return '$book $startChapter-$endChapter';
  }
}

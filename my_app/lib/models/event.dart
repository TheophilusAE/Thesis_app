class ChurchEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final int? maxCapacity;
  final bool isActive;
  final DateTime createdAt;

  const ChurchEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    this.maxCapacity,
    required this.isActive,
    required this.createdAt,
  });

  factory ChurchEvent.fromJson(Map<String, dynamic> json) => ChurchEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: (json['description'] as String?) ?? '',
        date: DateTime.parse(json['date'] as String).toLocal(),
        location: (json['location'] as String?) ?? '',
        maxCapacity: json['max_capacity'] as int?,
        isActive: (json['is_active'] as bool?) ?? true,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'date': date.toUtc().toIso8601String(),
        'location': location,
        'max_capacity': maxCapacity,
        'is_active': isActive,
      };

  ChurchEvent copyWith({
    String? title,
    String? description,
    DateTime? date,
    String? location,
    int? maxCapacity,
    bool? isActive,
  }) =>
      ChurchEvent(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        date: date ?? this.date,
        location: location ?? this.location,
        maxCapacity: maxCapacity ?? this.maxCapacity,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}

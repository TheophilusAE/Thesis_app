class PrayerRequest {
  final String id;
  final String userId;
  final String userName;
  final String category;
  final String content;
  final bool isAnonymous;
  final String status; // 'baru', 'didoakan', 'terjawab'
  final DateTime createdAt;
  final DateTime? updatedAt;

  PrayerRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.category,
    required this.content,
    this.isAnonymous = false,
    this.status = 'baru',
    required this.createdAt,
    this.updatedAt,
  });

  factory PrayerRequest.fromJson(Map<String, dynamic> json) {
    return PrayerRequest(
      id: json['id'] as String,
      userId: (json['user_id'] ?? '') as String,
      userName: (json['user_name'] ?? '') as String,
      category: (json['category'] ?? 'pribadi') as String,
      content: (json['content'] ?? '') as String,
      isAnonymous: (json['is_anonymous'] ?? false) as bool,
      status: (json['status'] ?? 'baru') as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'category': category,
      'content': content,
      'is_anonymous': isAnonymous,
      'status': status,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'category': category,
      'content': content,
      'is_anonymous': isAnonymous,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  PrayerRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? category,
    String? content,
    bool? isAnonymous,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrayerRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      category: category ?? this.category,
      content: content ?? this.content,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

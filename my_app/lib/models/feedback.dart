class UserFeedback {
  final String id;
  final String userId;
  final String userName;
  final String feedbackType;
  final String? eventId;
  final String? eventName;
  final int rating;
  final String message;
  final DateTime createdAt;
  final bool isAnonymous;

  UserFeedback({
    required this.id,
    required this.userId,
    required this.userName,
    required this.feedbackType,
    this.eventId,
    this.eventName,
    required this.rating,
    required this.message,
    required this.createdAt,
    this.isAnonymous = false,
  });

  factory UserFeedback.fromJson(Map<String, dynamic> json) {
    return UserFeedback(
      id: json['id'] as String,
      userId: (json['user_id'] ?? json['userId'] ?? '') as String,
      userName: (json['user_name'] ?? json['userName'] ?? '') as String,
      feedbackType: (json['feedback_type'] ?? json['feedbackType'] ?? 'general') as String,
      eventId: (json['event_id'] ?? json['eventId']) as String?,
      eventName: (json['event_name'] ?? json['eventName']) as String?,
      rating: (json['rating'] ?? 0) as int,
      message: (json['message'] ?? '') as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now()),
      isAnonymous: (json['is_anonymous'] ?? json['isAnonymous'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'feedback_type': feedbackType,
      'event_id': eventId,
      'event_name': eventName,
      'rating': rating,
      'message': message,
      'is_anonymous': isAnonymous,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'feedback_type': feedbackType,
      'event_id': eventId,
      'event_name': eventName,
      'rating': rating,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_anonymous': isAnonymous,
    };
  }
}

class UserFeedback {
  final String id;
  final String userId;
  final String userName;
  final String feedbackType; // 'event', 'facility', 'hospitality'
  final String? eventId; // null if feedback is for facility/hospitality
  final String? eventName; // null if feedback is for facility/hospitality
  final int rating; // 1-5 stars
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
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      feedbackType: json['feedbackType'],
      eventId: json['eventId'],
      eventName: json['eventName'],
      rating: json['rating'],
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
      isAnonymous: json['isAnonymous'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'feedbackType': feedbackType,
      'eventId': eventId,
      'eventName': eventName,
      'rating': rating,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isAnonymous': isAnonymous,
    };
  }
}

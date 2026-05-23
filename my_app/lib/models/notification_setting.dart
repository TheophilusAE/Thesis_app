class NotificationSetting {
  final String id;
  final String adminId;
  final List<int> hoursBeforeService; // e.g., [1, 3, 24] means 1 hour, 3 hours, 24 hours (1 day) before
  final bool enablePushNotifications;
  final bool enableInAppNotifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationSetting({
    required this.id,
    required this.adminId,
    required this.hoursBeforeService,
    required this.enablePushNotifications,
    required this.enableInAppNotifications,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adminId': adminId,
      'hoursBeforeService': hoursBeforeService,
      'enablePushNotifications': enablePushNotifications,
      'enableInAppNotifications': enableInAppNotifications,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory NotificationSetting.fromJson(Map<String, dynamic> json) {
    return NotificationSetting(
      id: json['id'] as String,
      adminId: json['adminId'] as String,
      hoursBeforeService: List<int>.from(json['hoursBeforeService'] as List),
      enablePushNotifications: json['enablePushNotifications'] as bool? ?? true,
      enableInAppNotifications: json['enableInAppNotifications'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Copy with modifications
  NotificationSetting copyWith({
    String? id,
    String? adminId,
    List<int>? hoursBeforeService,
    bool? enablePushNotifications,
    bool? enableInAppNotifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSetting(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      hoursBeforeService: hoursBeforeService ?? this.hoursBeforeService,
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
      enableInAppNotifications: enableInAppNotifications ?? this.enableInAppNotifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

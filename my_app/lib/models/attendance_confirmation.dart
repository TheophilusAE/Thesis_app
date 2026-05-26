class AttendanceConfirmation {
  final String id;
  final String userId;
  final String userName;
  final String serviceScheduleId;
  final DateTime scheduleDate;
  final bool confirmed;
  final DateTime? confirmedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AttendanceConfirmation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.serviceScheduleId,
    required this.scheduleDate,
    required this.confirmed,
    this.confirmedAt,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'serviceScheduleId': serviceScheduleId,
      'scheduleDate': scheduleDate.toIso8601String(),
      'confirmed': confirmed,
      'confirmedAt': confirmedAt?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory AttendanceConfirmation.fromJson(Map<String, dynamic> json) {
    return AttendanceConfirmation(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      serviceScheduleId: json['serviceScheduleId'] as String,
      scheduleDate: DateTime.parse(json['scheduleDate'] as String),
      confirmed: json['confirmed'] as bool? ?? false,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Copy with updates
  AttendanceConfirmation copyWith({
    String? id,
    String? userId,
    String? userName,
    String? serviceScheduleId,
    DateTime? scheduleDate,
    bool? confirmed,
    DateTime? confirmedAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceConfirmation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      serviceScheduleId: serviceScheduleId ?? this.serviceScheduleId,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      confirmed: confirmed ?? this.confirmed,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

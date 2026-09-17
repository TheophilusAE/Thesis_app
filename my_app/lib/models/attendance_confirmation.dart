class AttendanceConfirmation {
  final String id;
  final String userId;
  final String userName;
  final String serviceScheduleId;
  final DateTime scheduleDate;
  final bool confirmed;
  final DateTime? confirmedAt;
  final String? notes;
  final String checkInMethod; // 'manual' or 'qr'
  final String? checkedInBy; // user id of the pelayan who scanned, if any
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
    this.checkInMethod = 'manual',
    this.checkedInBy,
    required this.createdAt,
    this.updatedAt,
  });

  factory AttendanceConfirmation.fromJson(Map<String, dynamic> json) {
    return AttendanceConfirmation(
      id: json['id'] as String,
      userId: (json['user_id'] ?? json['userId'] ?? '') as String,
      userName: (json['user_name'] ?? json['userName'] ?? '') as String,
      serviceScheduleId: (json['service_schedule_id'] ?? json['serviceScheduleId'] ?? '') as String,
      scheduleDate: DateTime.parse((json['schedule_date'] ?? json['scheduleDate']) as String),
      confirmed: (json['confirmed'] ?? false) as bool,
      confirmedAt: (json['confirmed_at'] ?? json['confirmedAt']) != null
          ? DateTime.parse((json['confirmed_at'] ?? json['confirmedAt']) as String)
          : null,
      notes: json['notes'] as String?,
      checkInMethod: (json['check_in_method'] ?? json['checkInMethod'] ?? 'manual') as String,
      checkedInBy: (json['checked_in_by'] ?? json['checkedInBy']) as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now()),
      updatedAt: (json['updated_at'] ?? json['updatedAt']) != null
          ? DateTime.parse((json['updated_at'] ?? json['updatedAt']) as String)
          : null,
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'service_schedule_id': serviceScheduleId,
      'schedule_date': scheduleDate.toIso8601String(),
      'confirmed': confirmed,
      'confirmed_at': confirmedAt?.toIso8601String(),
      'notes': notes,
      'check_in_method': checkInMethod,
      'checked_in_by': checkedInBy,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'service_schedule_id': serviceScheduleId,
      'schedule_date': scheduleDate.toIso8601String(),
      'confirmed': confirmed,
      'confirmed_at': confirmedAt?.toIso8601String(),
      'notes': notes,
      'check_in_method': checkInMethod,
      'checked_in_by': checkedInBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  AttendanceConfirmation copyWith({
    String? id,
    String? userId,
    String? userName,
    String? serviceScheduleId,
    DateTime? scheduleDate,
    bool? confirmed,
    DateTime? confirmedAt,
    String? notes,
    String? checkInMethod,
    String? checkedInBy,
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
      checkInMethod: checkInMethod ?? this.checkInMethod,
      checkedInBy: checkedInBy ?? this.checkedInBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

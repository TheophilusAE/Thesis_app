class ServiceSchedule {
  final String id;
  final String pelayaniId;
  final String pelayaniName;
  final String pelayaniPosition;
  final DateTime serviceDate;
  final String startTime;
  final String endTime;
  final String serviceType;
  final bool isRecurring;
  final String recurringPattern;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceSchedule({
    required this.id,
    required this.pelayaniId,
    required this.pelayaniName,
    required this.pelayaniPosition,
    required this.serviceDate,
    required this.startTime,
    required this.endTime,
    required this.serviceType,
    required this.isRecurring,
    required this.recurringPattern,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceSchedule.fromJson(Map<String, dynamic> json) {
    return ServiceSchedule(
      id: json['id'] as String,
      pelayaniId: (json['pelayan_id'] ?? json['pelayaniId'] ?? '') as String,
      pelayaniName: (json['pelayan_name'] ?? json['pelayaniName'] ?? '') as String,
      pelayaniPosition: (json['pelayan_position'] ?? json['pelayaniPosition'] ?? '') as String,
      serviceDate: DateTime.parse((json['service_date'] ?? json['serviceDate']) as String),
      startTime: (json['start_time'] ?? json['startTime'] ?? '') as String,
      endTime: (json['end_time'] ?? json['endTime'] ?? '') as String,
      serviceType: (json['service_type'] ?? json['serviceType'] ?? '') as String,
      isRecurring: (json['is_recurring'] ?? json['isRecurring'] ?? false) as bool,
      recurringPattern: (json['recurring_pattern'] ?? json['recurringPattern'] ?? '') as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : (json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now()),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'pelayan_id': pelayaniId,
      'pelayan_name': pelayaniName,
      'pelayan_position': pelayaniPosition,
      'service_date': serviceDate.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'service_type': serviceType,
      'is_recurring': isRecurring,
      'recurring_pattern': recurringPattern,
      'notes': notes,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pelayan_id': pelayaniId,
      'pelayan_name': pelayaniName,
      'pelayan_position': pelayaniPosition,
      'service_date': serviceDate.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'service_type': serviceType,
      'is_recurring': isRecurring,
      'recurring_pattern': recurringPattern,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ServiceSchedule copyWith({
    String? id,
    String? pelayaniId,
    String? pelayaniName,
    String? pelayaniPosition,
    DateTime? serviceDate,
    String? startTime,
    String? endTime,
    String? serviceType,
    bool? isRecurring,
    String? recurringPattern,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceSchedule(
      id: id ?? this.id,
      pelayaniId: pelayaniId ?? this.pelayaniId,
      pelayaniName: pelayaniName ?? this.pelayaniName,
      pelayaniPosition: pelayaniPosition ?? this.pelayaniPosition,
      serviceDate: serviceDate ?? this.serviceDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      serviceType: serviceType ?? this.serviceType,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

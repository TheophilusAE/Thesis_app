class SubstitutionRequest {
  final String id;
  final String serviceScheduleId;
  final String requestedByUserId;
  final String requestedByName;
  final String? replacementUserId;
  final String? replacementName;
  final String reason;
  final String status;
  final String? adminNotes;
  final String? requestedReplacementName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? reviewedAt;
  final String? reviewedByAdminId;

  SubstitutionRequest({
    required this.id,
    required this.serviceScheduleId,
    required this.requestedByUserId,
    required this.requestedByName,
    this.replacementUserId,
    this.replacementName,
    required this.reason,
    this.status = 'pending',
    this.adminNotes,
    this.requestedReplacementName,
    required this.createdAt,
    this.updatedAt,
    this.reviewedAt,
    this.reviewedByAdminId,
  });

  factory SubstitutionRequest.fromJson(Map<String, dynamic> json) {
    return SubstitutionRequest(
      id: json['id'] as String,
      serviceScheduleId: (json['service_schedule_id'] ?? json['serviceScheduleId'] ?? '') as String,
      requestedByUserId: (json['requested_by_user_id'] ?? json['requestedByUserId'] ?? '') as String,
      requestedByName: (json['requested_by_name'] ?? json['requestedByName'] ?? '') as String,
      replacementUserId: (json['replacement_user_id'] ?? json['replacementUserId']) as String?,
      replacementName: (json['replacement_name'] ?? json['replacementName']) as String?,
      reason: (json['reason'] ?? '') as String,
      status: (json['status'] ?? 'pending') as String,
      adminNotes: (json['admin_notes'] ?? json['adminNotes']) as String?,
      requestedReplacementName: (json['requested_replacement_name'] ?? json['requestedReplacementName']) as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now()),
      updatedAt: (json['updated_at'] ?? json['updatedAt']) != null
          ? DateTime.parse((json['updated_at'] ?? json['updatedAt']) as String)
          : null,
      reviewedAt: (json['reviewed_at'] ?? json['reviewedAt']) != null
          ? DateTime.parse((json['reviewed_at'] ?? json['reviewedAt']) as String)
          : null,
      reviewedByAdminId: (json['reviewed_by_admin_id'] ?? json['reviewedByAdminId']) as String?,
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'service_schedule_id': serviceScheduleId,
      'requested_by_user_id': requestedByUserId,
      'requested_by_name': requestedByName,
      'replacement_user_id': replacementUserId,
      'replacement_name': replacementName,
      'reason': reason,
      'status': status,
      'admin_notes': adminNotes,
      'requested_replacement_name': requestedReplacementName,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_schedule_id': serviceScheduleId,
      'requested_by_user_id': requestedByUserId,
      'requested_by_name': requestedByName,
      'replacement_user_id': replacementUserId,
      'replacement_name': replacementName,
      'reason': reason,
      'status': status,
      'admin_notes': adminNotes,
      'requested_replacement_name': requestedReplacementName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by_admin_id': reviewedByAdminId,
    };
  }

  SubstitutionRequest copyWith({
    String? id,
    String? serviceScheduleId,
    String? requestedByUserId,
    String? requestedByName,
    String? replacementUserId,
    String? replacementName,
    String? reason,
    String? status,
    String? adminNotes,
    String? requestedReplacementName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? reviewedAt,
    String? reviewedByAdminId,
  }) {
    return SubstitutionRequest(
      id: id ?? this.id,
      serviceScheduleId: serviceScheduleId ?? this.serviceScheduleId,
      requestedByUserId: requestedByUserId ?? this.requestedByUserId,
      requestedByName: requestedByName ?? this.requestedByName,
      replacementUserId: replacementUserId ?? this.replacementUserId,
      replacementName: replacementName ?? this.replacementName,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      requestedReplacementName: requestedReplacementName ?? this.requestedReplacementName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedByAdminId: reviewedByAdminId ?? this.reviewedByAdminId,
    );
  }
}

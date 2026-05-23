class SubstitutionRequest {
  final String id;
  final String serviceScheduleId; // Reference to ServiceSchedule being substituted
  final String requestedByUserId; // Pelayan requesting substitution
  final String requestedByName;
  final String? replacementUserId; // Person to replace them (optional at request time)
  final String? replacementName;
  final String reason; // Reason for substitution request
  final String status; // 'pending', 'approved', 'rejected', 'completed'
  final String? adminNotes; // Notes from admin when approving/rejecting
  final String? requestedReplacementName; // If requesting specific person but name provided
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? reviewedAt; // When admin reviewed it
  final String? reviewedByAdminId; // Which admin reviewed it

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

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceScheduleId': serviceScheduleId,
      'requestedByUserId': requestedByUserId,
      'requestedByName': requestedByName,
      'replacementUserId': replacementUserId,
      'replacementName': replacementName,
      'reason': reason,
      'status': status,
      'adminNotes': adminNotes,
      'requestedReplacementName': requestedReplacementName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedByAdminId': reviewedByAdminId,
    };
  }

  /// Create from JSON
  factory SubstitutionRequest.fromJson(Map<String, dynamic> json) {
    return SubstitutionRequest(
      id: json['id'] as String,
      serviceScheduleId: json['serviceScheduleId'] as String,
      requestedByUserId: json['requestedByUserId'] as String,
      requestedByName: json['requestedByName'] as String,
      replacementUserId: json['replacementUserId'] as String?,
      replacementName: json['replacementName'] as String?,
      reason: json['reason'] as String,
      status: json['status'] as String? ?? 'pending',
      adminNotes: json['adminNotes'] as String?,
      requestedReplacementName: json['requestedReplacementName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      reviewedAt: json['reviewedAt'] != null 
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      reviewedByAdminId: json['reviewedByAdminId'] as String?,
    );
  }

  /// Copy with updates
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

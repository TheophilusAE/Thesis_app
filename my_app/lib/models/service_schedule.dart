import 'package:flutter/material.dart';

class ServiceSchedule {
  final String id;
  final String pelayaniId;
  final String pelayaniName;
  final String pelayaniPosition;
  final DateTime serviceDate;
  final String startTime; // Format: "HH:mm"
  final String endTime; // Format: "HH:mm"
  final String serviceType; // e.g., "Ibadah Minggu", "Ibadah Malam", "Doa Syafaat"
  final bool isRecurring; // true jika jadwal tetap (setiap Minggu, dll)
  final String recurringPattern; // "WEEKLY", "BI_WEEKLY", "MONTHLY", dll
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

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pelayaniId': pelayaniId,
      'pelayaniName': pelayaniName,
      'pelayaniPosition': pelayaniPosition,
      'serviceDate': serviceDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'serviceType': serviceType,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ServiceSchedule.fromJson(Map<String, dynamic> json) {
    return ServiceSchedule(
      id: json['id'] as String,
      pelayaniId: json['pelayaniId'] as String,
      pelayaniName: json['pelayaniName'] as String,
      pelayaniPosition: json['pelayaniPosition'] as String,
      serviceDate: DateTime.parse(json['serviceDate'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      serviceType: json['serviceType'] as String,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringPattern: json['recurringPattern'] as String? ?? '',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Copy with modifications
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


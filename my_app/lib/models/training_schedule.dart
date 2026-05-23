class TrainingSchedule {
  final String id;
  final String nama;
  final DateTime trainingDate;
  final String startTime; // Format: "HH:mm"
  final String endTime; // Format: "HH:mm"
  final String deskripsi;
  final List<String> pelayaniIds; // List of Pelayan IDs yang mengikuti latihan ini
  final String lokasi; // Location of training
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainingSchedule({
    required this.id,
    required this.nama,
    required this.trainingDate,
    required this.startTime,
    required this.endTime,
    required this.deskripsi,
    required this.pelayaniIds,
    required this.lokasi,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'trainingDate': trainingDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'deskripsi': deskripsi,
      'pelayaniIds': pelayaniIds,
      'lokasi': lokasi,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory TrainingSchedule.fromJson(Map<String, dynamic> json) {
    return TrainingSchedule(
      id: json['id'] as String,
      nama: json['nama'] as String,
      trainingDate: DateTime.parse(json['trainingDate'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      deskripsi: json['deskripsi'] as String,
      pelayaniIds: List<String>.from(json['pelayaniIds'] as List),
      lokasi: json['lokasi'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Copy with modifications
  TrainingSchedule copyWith({
    String? id,
    String? nama,
    DateTime? trainingDate,
    String? startTime,
    String? endTime,
    String? deskripsi,
    List<String>? pelayaniIds,
    String? lokasi,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainingSchedule(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      trainingDate: trainingDate ?? this.trainingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      deskripsi: deskripsi ?? this.deskripsi,
      pelayaniIds: pelayaniIds ?? this.pelayaniIds,
      lokasi: lokasi ?? this.lokasi,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

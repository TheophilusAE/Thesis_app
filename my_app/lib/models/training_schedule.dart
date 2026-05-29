class TrainingSchedule {
  final String id;
  final String nama;
  final DateTime trainingDate;
  final String startTime;
  final String endTime;
  final String deskripsi;
  final List<String> pelayaniIds;
  final String lokasi;
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

  factory TrainingSchedule.fromJson(Map<String, dynamic> json) {
    return TrainingSchedule(
      id: json['id'] as String,
      nama: (json['nama'] ?? '') as String,
      trainingDate: DateTime.parse((json['training_date'] ?? json['trainingDate']) as String),
      startTime: (json['start_time'] ?? json['startTime'] ?? '') as String,
      endTime: (json['end_time'] ?? json['endTime'] ?? '') as String,
      deskripsi: (json['deskripsi'] ?? '') as String,
      pelayaniIds: json['pelayan_ids'] != null
          ? List<String>.from(json['pelayan_ids'] as List)
          : (json['pelayaniIds'] != null
              ? List<String>.from(json['pelayaniIds'] as List)
              : []),
      lokasi: (json['lokasi'] ?? '') as String,
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
      'nama': nama,
      'training_date': trainingDate.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'deskripsi': deskripsi,
      'pelayan_ids': pelayaniIds,
      'lokasi': lokasi,
      'notes': notes,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'training_date': trainingDate.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'deskripsi': deskripsi,
      'pelayan_ids': pelayaniIds,
      'lokasi': lokasi,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

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

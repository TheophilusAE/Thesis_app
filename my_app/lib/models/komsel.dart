class Komsel {
  final String id;
  final String nama;
  final String wilayah;
  final String leaderName;
  final String leaderPhone;
  final String meetingSchedule;
  final String location;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Komsel({
    required this.id,
    required this.nama,
    this.wilayah = '',
    this.leaderName = '',
    this.leaderPhone = '',
    this.meetingSchedule = '',
    this.location = '',
    this.description = '',
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Komsel.fromJson(Map<String, dynamic> json) {
    return Komsel(
      id: json['id'] as String,
      nama: (json['nama'] ?? '') as String,
      wilayah: (json['wilayah'] ?? '') as String,
      leaderName: (json['leader_name'] ?? '') as String,
      leaderPhone: (json['leader_phone'] ?? '') as String,
      meetingSchedule: (json['meeting_schedule'] ?? '') as String,
      location: (json['location'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      isActive: (json['is_active'] ?? true) as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'nama': nama,
      'wilayah': wilayah,
      'leader_name': leaderName,
      'leader_phone': leaderPhone,
      'meeting_schedule': meetingSchedule,
      'location': location,
      'description': description,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      ...toSupabaseJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Komsel copyWith({
    String? id,
    String? nama,
    String? wilayah,
    String? leaderName,
    String? leaderPhone,
    String? meetingSchedule,
    String? location,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Komsel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      wilayah: wilayah ?? this.wilayah,
      leaderName: leaderName ?? this.leaderName,
      leaderPhone: leaderPhone ?? this.leaderPhone,
      meetingSchedule: meetingSchedule ?? this.meetingSchedule,
      location: location ?? this.location,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

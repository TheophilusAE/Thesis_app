class Pelayan {
  final String id;
  final String userId; // Reference to User
  final String nama;
  final String noTelepon;
  final String posisi; // e.g., "Opsir", "Cantor", "Penjaga"
  final bool isAktif;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pelayan({
    required this.id,
    required this.userId,
    required this.nama,
    required this.noTelepon,
    required this.posisi,
    required this.isAktif,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert Pelayan object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'nama': nama,
      'noTelepon': noTelepon,
      'posisi': posisi,
      'isAktif': isAktif,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create Pelayan object from JSON
  factory Pelayan.fromJson(Map<String, dynamic> json) {
    return Pelayan(
      id: json['id'] as String,
      userId: json['userId'] as String,
      nama: json['nama'] as String,
      noTelepon: json['noTelepon'] as String,
      posisi: json['posisi'] as String,
      isAktif: json['isAktif'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Create a copy of Pelayan with modified fields
  Pelayan copyWith({
    String? id,
    String? userId,
    String? nama,
    String? noTelepon,
    String? posisi,
    bool? isAktif,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pelayan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nama: nama ?? this.nama,
      noTelepon: noTelepon ?? this.noTelepon,
      posisi: posisi ?? this.posisi,
      isAktif: isAktif ?? this.isAktif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

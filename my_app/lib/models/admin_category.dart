/// One row of `public.admin_categories` — an area of church administration
/// (e.g. Umum, Pemuda, Sekolah Minggu) that an Admin can be limited to.
class AdminCategory {
  final String id;
  final String kode;
  final String nama;
  final bool isActive;

  const AdminCategory({
    required this.id,
    required this.kode,
    required this.nama,
    this.isActive = true,
  });

  factory AdminCategory.fromJson(Map<String, dynamic> json) {
    return AdminCategory(
      id: json['id'] as String,
      kode: (json['kode'] ?? '') as String,
      nama: (json['nama'] ?? '') as String,
      isActive: (json['is_active'] ?? true) as bool,
    );
  }

  /// Builds a database-safe code (`^[a-z0-9_]+$`) from a display name,
  /// e.g. "Sekolah Minggu" → "sekolah_minggu".
  static String codeFromName(String name) {
    final code = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return code;
  }
}

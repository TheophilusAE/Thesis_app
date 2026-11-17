/// Church-specific settings that have no database column.
///
/// The schema has no "building capacity" field, and it must not be changed,
/// so the seating capacity used by the decision-support feature
/// ("Rekomendasi Kegiatan", RQ4/OBJ4) lives here as a constant.
class ChurchConfig {
  ChurchConfig._();

  /// Seating capacity of the GPdI Persadamas Banjarmasin worship hall.
  ///
  /// Set this to the verified number of seats before release, e.g. `= 250;`.
  /// While it is null, the recommendation screen shows "kapasitas gedung
  /// belum dikonfigurasi" and skips every capacity-based rule instead of
  /// guessing a number.
  static const int? buildingCapacity = null;
}

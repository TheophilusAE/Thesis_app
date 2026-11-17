/// Labels for the admin attendance monitor (KF-10).
///
/// The `attendance` table stores no role, so a row's role is derived from
/// the attendee's *current* `users.roles`. That is the best available
/// signal without a schema change, but it is not the role they held at
/// check-in time — the screen states this limitation.
library;

const String roleFilterAll = 'all';
const String rolePelayan = 'pelayan';
const String roleJemaat = 'jemaat';

/// Groups an attendee as `pelayan` (holds the pelayan role) or `jemaat`
/// (everyone else, including admin-only accounts). Unknown users (deleted
/// accounts, users not loaded) count as `jemaat`.
String attendeeGroup(List<String>? roles) {
  if (roles != null && roles.contains(rolePelayan)) return rolePelayan;
  return roleJemaat;
}

String attendeeGroupLabel(String group) => group == rolePelayan ? 'Pelayan' : 'Jemaat';

/// Human-readable check-in path. `checked_in_by` is set only when a
/// pelayan scanned someone else's member card; a QR row without it is a
/// self check-in from the projected service QR.
String checkInMethodLabel(String method, {String? checkedInBy, String? checkerName}) {
  if (method == 'qr') {
    if (checkedInBy == null || checkedInBy.isEmpty) return 'QR mandiri';
    return (checkerName == null || checkerName.isEmpty)
        ? 'QR oleh petugas'
        : 'QR oleh petugas ($checkerName)';
  }
  return 'Konfirmasi manual';
}

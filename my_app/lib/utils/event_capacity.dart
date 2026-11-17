/// Event capacity arithmetic (KF-17), kept pure so it can be unit-tested.
///
/// The database has no constraint or trigger enforcing `max_capacity`, so the
/// app re-checks it immediately before every registration write. Two people
/// registering at the very same moment can still both pass this check — a
/// strict guarantee would need a database-side constraint, which is out of
/// scope (the schema must not change).
library;

/// Seats still available to a user, given the current headcount reported by
/// `get_event_registration_count`. [existingTotal] is that user's own
/// current registration size (0 if not yet registered): when editing, their
/// existing seats are freed before the new size is checked.
///
/// Returns null when the event has no capacity limit.
int? remainingCapacity({
  required int? maxCapacity,
  required int currentCount,
  int existingTotal = 0,
}) {
  if (maxCapacity == null) return null;
  final remaining = maxCapacity - (currentCount - existingTotal);
  return remaining < 0 ? 0 : remaining;
}

/// Whether a registration of [requestedTotal] people fits.
bool fitsCapacity({
  required int? maxCapacity,
  required int currentCount,
  required int requestedTotal,
  int existingTotal = 0,
}) {
  final remaining = remainingCapacity(
    maxCapacity: maxCapacity,
    currentCount: currentCount,
    existingTotal: existingTotal,
  );
  return remaining == null || requestedTotal <= remaining;
}

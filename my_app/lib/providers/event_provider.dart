import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../models/event_registration.dart';
import '../services/event_service.dart';

class EventProvider extends ChangeNotifier {
  final _service = EventService();

  List<ChurchEvent> _events = [];
  bool _loading = false;

  List<ChurchEvent> get events => _events;
  List<ChurchEvent> get activeEvents =>
      _events.where((e) => e.isActive).toList();
  bool get isLoading => _loading;

  Future<void> loadActiveEvents() async {
    _loading = true;
    notifyListeners();
    _events = await _service.getActiveEvents();
    _loading = false;
    notifyListeners();
  }

  Future<void> loadAllEvents() async {
    _loading = true;
    notifyListeners();
    _events = await _service.getAllEvents();
    _loading = false;
    notifyListeners();
  }

  Future<bool> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String location,
    int? maxCapacity,
  }) async {
    final ok = await _service.createEvent(
      title: title,
      description: description,
      date: date,
      location: location,
      maxCapacity: maxCapacity,
    );
    if (ok) await loadAllEvents();
    return ok;
  }

  Future<bool> updateEvent(ChurchEvent event) async {
    final ok = await _service.updateEvent(event);
    if (ok) await loadAllEvents();
    return ok;
  }

  Future<bool> deleteEvent(String eventId) async {
    final ok = await _service.deleteEvent(eventId);
    if (ok) await loadAllEvents();
    return ok;
  }

  Future<bool> toggleActive(String eventId, {required bool isActive}) async {
    final ok = await _service.toggleActive(eventId, isActive: isActive);
    if (ok) await loadAllEvents();
    return ok;
  }

  Future<EventRegistration?> getUserRegistration(
          String eventId, String userId) =>
      _service.getUserRegistration(eventId, userId);

  Future<bool> registerForEvent({
    required String eventId,
    required String userId,
    required List<FamilyMember> familyMembers,
    String? notes,
  }) =>
      _service.registerForEvent(
        eventId: eventId,
        userId: userId,
        familyMembers: familyMembers,
        notes: notes,
      );

  Future<bool> cancelRegistration(String eventId, String userId) =>
      _service.cancelRegistration(eventId, userId);

  Future<int> getRegisteredCount(String eventId) =>
      _service.getRegisteredCount(eventId);

  Future<List<EventRegistration>> getEventRegistrations(String eventId) =>
      _service.getEventRegistrations(eventId);
}

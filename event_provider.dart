import 'package:flutter/material.dart';
import 'dart:io';
import 'models/event_model.dart';
import 'services/event_service.dart';

class EventProvider extends ChangeNotifier {
  final EventService _eventService = EventService();
  List<EventModel> _events = [];
  List<EventModel> _upcomingEvents = [];
  List<EventModel> _registeredEvents = [];
  List<EventModel> _interestedEvents = [];
  bool _isLoading = false;
  String? _error;

  List<EventModel> get events => _events;
  List<EventModel> get upcomingEvents => _upcomingEvents;
  List<EventModel> get registeredEvents => _registeredEvents;
  List<EventModel> get interestedEvents => _interestedEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize events
  void initializeEvents() {
    _eventService.getAllEvents().listen(
      (events) {
        _events = events;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Initialize upcoming events
  void initializeUpcomingEvents() {
    _eventService.getUpcomingEvents().listen(
      (events) {
        _upcomingEvents = events;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Initialize user's registered events
  void initializeRegisteredEvents(String userId) {
    _eventService.getRegisteredEvents(userId).listen(
      (events) {
        _registeredEvents = events;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Initialize user's interested events
  void initializeInterestedEvents(String userId) {
    _eventService.getInterestedEvents(userId).listen(
      (events) {
        _interestedEvents = events;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Create event
  Future<void> createEvent({
    required String title,
    required String description,
    required String organizerId,
    required EventType type,
    required DateTime startDate,
    required DateTime endDate,
    required String location,
    File? imageFile,
    double? fee,
    required List<String> sports,
    required List<String> requirements,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _eventService.createEvent(
        title: title,
        description: description,
        organizerId: organizerId,
        type: type,
        startDate: startDate,
        endDate: endDate,
        location: location,
        imageFile: imageFile,
        fee: fee,
        sports: sports,
        requirements: requirements,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register for event
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      await _eventService.registerForEvent(eventId, userId);
      final index = _events.indexWhere((event) => event.id == eventId);
      if (index != -1) {
        _events[index] = _events[index].copyWith(
          registeredUsers: [..._events[index].registeredUsers, userId],
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Show interest in event
  Future<void> showInterestInEvent(String eventId, String userId) async {
    try {
      await _eventService.showInterestInEvent(eventId, userId);
      final index = _events.indexWhere((event) => event.id == eventId);
      if (index != -1) {
        _events[index] = _events[index].copyWith(
          interestedUsers: [..._events[index].interestedUsers, userId],
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Remove interest in event
  Future<void> removeInterestInEvent(String eventId, String userId) async {
    try {
      await _eventService.removeInterestInEvent(eventId, userId);
      final index = _events.indexWhere((event) => event.id == eventId);
      if (index != -1) {
        _events[index] = _events[index].copyWith(
          interestedUsers: _events[index].interestedUsers
              .where((id) => id != userId)
              .toList(),
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update event
  Future<void> updateEvent(EventModel event) async {
    try {
      await _eventService.updateEvent(event);
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = event;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventService.deleteEvent(eventId);
      _events.removeWhere((event) => event.id == eventId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Search events
  Stream<List<EventModel>> searchEvents(String query) {
    return _eventService.searchEvents(query);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 
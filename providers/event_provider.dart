import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventProvider with ChangeNotifier {
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

  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      await _eventService.registerForEvent(eventId, userId);
      _clearError();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> showInterestInEvent(String eventId, String userId) async {
    try {
      await _eventService.showInterestInEvent(eventId, userId);
      _clearError();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> removeInterestInEvent(String eventId, String userId) async {
    try {
      await _eventService.removeInterestInEvent(eventId, userId);
      _clearError();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> updateEvent(EventModel event) async {
    try {
      await _eventService.updateEvent(event);
      _clearError();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventService.deleteEvent(eventId);
      _clearError();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
} 
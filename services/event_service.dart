import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<EventModel>> getAllEvents() {
    try {
      return _firestore
          .collection('events')
          .orderBy('startDate', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                return EventModel.fromFirestore(data);
              })
              .where((event) => event != null)
              .cast<EventModel>()
              .toList());
    } catch (e) {
      print('Error getting all events: $e');
      return Stream.value([]);
    }
  }

  Stream<List<EventModel>> getUpcomingEvents() {
    try {
      final now = DateTime.now();
      return _firestore
          .collection('events')
          .where('startDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('startDate', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                return EventModel.fromFirestore(data);
              })
              .where((event) => event != null)
              .cast<EventModel>()
              .toList());
    } catch (e) {
      print('Error getting upcoming events: $e');
      return Stream.value([]);
    }
  }

  Stream<List<EventModel>> getRegisteredEvents(String userId) {
    try {
      return _firestore
          .collection('events')
          .where('registeredUsers', arrayContains: userId)
          .orderBy('startDate', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                return EventModel.fromFirestore(data);
              })
              .where((event) => event != null)
              .cast<EventModel>()
              .toList());
    } catch (e) {
      print('Error getting registered events: $e');
      return Stream.value([]);
    }
  }

  Stream<List<EventModel>> getInterestedEvents(String userId) {
    try {
      return _firestore
          .collection('events')
          .where('interestedUsers', arrayContains: userId)
          .orderBy('startDate', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                return EventModel.fromFirestore(data);
              })
              .where((event) => event != null)
              .cast<EventModel>()
              .toList());
    } catch (e) {
      print('Error getting interested events: $e');
      return Stream.value([]);
    }
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
    try {
      String? imageUrl;
      if (imageFile != null) {
        final ref = _storage
            .ref()
            .child('events/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      final event = EventModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        organizerId: organizerId,
        type: type,
        startDate: startDate,
        endDate: endDate,
        location: location,
        imageUrl: imageUrl,
        fee: fee,
        sports: sports,
        requirements: requirements,
        registeredUsers: [],
        interestedUsers: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('events').doc(event.id).set(event.toFirestore());
    } catch (e) {
      print('Error creating event: $e');
      rethrow;
    }
  }

  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      final eventRef = _firestore.collection('events').doc(eventId);
      final event = await eventRef.get();
      
      if (!event.exists) {
        throw Exception('Event not found');
      }

      final data = event.data();
      if (data == null) {
        throw Exception('Event data is null');
      }

      final eventData = EventModel.fromFirestore(data);
      final registeredUsers = List<String>.from(eventData.registeredUsers)..add(userId);

      await eventRef.update({'registeredUsers': registeredUsers});
    } catch (e) {
      print('Error registering for event: $e');
      rethrow;
    }
  }

  Future<void> showInterestInEvent(String eventId, String userId) async {
    try {
      final eventRef = _firestore.collection('events').doc(eventId);
      final event = await eventRef.get();
      
      if (!event.exists) {
        throw Exception('Event not found');
      }

      final data = event.data();
      if (data == null) {
        throw Exception('Event data is null');
      }

      final eventData = EventModel.fromFirestore(data);
      final interestedUsers = List<String>.from(eventData.interestedUsers)..add(userId);

      await eventRef.update({'interestedUsers': interestedUsers});
    } catch (e) {
      print('Error showing interest in event: $e');
      rethrow;
    }
  }

  Future<void> removeInterestInEvent(String eventId, String userId) async {
    try {
      final eventRef = _firestore.collection('events').doc(eventId);
      final event = await eventRef.get();
      
      if (!event.exists) {
        throw Exception('Event not found');
      }

      final data = event.data();
      if (data == null) {
        throw Exception('Event data is null');
      }

      final eventData = EventModel.fromFirestore(data);
      final interestedUsers = eventData.interestedUsers.where((id) => id != userId).toList();

      await eventRef.update({'interestedUsers': interestedUsers});
    } catch (e) {
      print('Error removing interest from event: $e');
      rethrow;
    }
  }

  Future<void> updateEvent(EventModel event) async {
    try {
      await _firestore.collection('events').doc(event.id).update(event.toFirestore());
    } catch (e) {
      print('Error updating event: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      final eventRef = _firestore.collection('events').doc(eventId);
      final event = await eventRef.get();
      
      if (!event.exists) {
        throw Exception('Event not found');
      }

      final data = event.data();
      if (data == null) {
        throw Exception('Event data is null');
      }

      final eventData = EventModel.fromFirestore(data);
      
      // Delete image from storage if exists
      if (eventData.imageUrl != null) {
        try {
          await _storage.refFromURL(eventData.imageUrl!).delete();
        } catch (e) {
          print('Error deleting image: $e');
        }
      }

      await eventRef.delete();
    } catch (e) {
      print('Error deleting event: $e');
      rethrow;
    }
  }

  Stream<List<EventModel>> searchEvents(String query) {
    try {
      final lowercaseQuery = query.toLowerCase();
      return _firestore
          .collection('events')
          .orderBy('startDate', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                return EventModel.fromFirestore(data);
              })
              .where((event) => event != null)
              .cast<EventModel>()
              .where((event) =>
                  event.title.toLowerCase().contains(lowercaseQuery) ||
                  event.description.toLowerCase().contains(lowercaseQuery) ||
                  event.location.toLowerCase().contains(lowercaseQuery) ||
                  event.sports.any((sport) => sport.toLowerCase().contains(lowercaseQuery)))
              .toList());
    } catch (e) {
      print('Error searching events: $e');
      return Stream.value([]);
    }
  }
} 
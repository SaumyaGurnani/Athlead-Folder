import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create event
  Future<EventModel> createEvent({
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
        final ref = _storage.ref().child('events/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      final event = EventModel(
        id: '',
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

      final docRef = await _firestore.collection('events').add(event.toFirestore());
      return event.copyWith(id: docRef.id);
    } catch (e) {
      rethrow;
    }
  }

  // Get all events
  Stream<List<EventModel>> getAllEvents() {
    return _firestore
        .collection('events')
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc.data())).toList());
  }

  // Get upcoming events
  Stream<List<EventModel>> getUpcomingEvents() {
    return _firestore
        .collection('events')
        .where('startDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc.data())).toList());
  }

  // Get events by type
  Stream<List<EventModel>> getEventsByType(EventType type) {
    return _firestore
        .collection('events')
        .where('type', isEqualTo: type.toString().split('.').last)
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc.data())).toList());
  }

  // Get events by organizer
  Stream<List<EventModel>> getEventsByOrganizer(String organizerId) {
    return _firestore
        .collection('events')
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc.data())).toList());
  }

  // Register for event
  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'registeredUsers': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Show interest in event
  Future<void> showInterestInEvent(String eventId, String userId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'interestedUsers': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Remove interest in event
  Future<void> removeInterestInEvent(String eventId, String userId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'interestedUsers': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Update event
  Future<void> updateEvent(EventModel event) async {
    try {
      await _firestore
          .collection('events')
          .doc(event.id)
          .update(event.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      final event = await _firestore.collection('events').doc(eventId).get();
      final eventData = EventModel.fromFirestore(event.data()!);

      if (eventData.imageUrl != null) {
        try {
          final ref = _storage.refFromURL(eventData.imageUrl!);
          await ref.delete();
        } catch (e) {
          // Ignore errors if image doesn't exist
        }
      }

      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Search events
  Stream<List<EventModel>> searchEvents(String query) {
    return _firestore
        .collection('events')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc.data())).toList());
  }

  // Get registered events for user
  Stream<List<EventModel>> getRegisteredEvents(String userId) {
    return _firestore
        .collection('events')
        .where('registeredUsers', arrayContains: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc.data())).toList());
  }

  // Get interested events for user
  Stream<List<EventModel>> getInterestedEvents(String userId) {
    return _firestore
        .collection('events')
        .where('interestedUsers', arrayContains: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc.data())).toList());
  }
} 
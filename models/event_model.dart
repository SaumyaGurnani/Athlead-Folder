import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType {
  competition,
  training,
  workshop,
  seminar,
  meetup,
  other,
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final String organizerId;
  final EventType type;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String? imageUrl;
  final double? fee;
  final List<String> sports;
  final List<String> requirements;
  final List<String> registeredUsers;
  final List<String> interestedUsers;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.organizerId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.location,
    this.imageUrl,
    this.fee,
    required this.sports,
    required this.requirements,
    required this.registeredUsers,
    required this.interestedUsers,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'organizerId': organizerId,
      'type': type.toString().split('.').last,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'location': location,
      'imageUrl': imageUrl,
      'fee': fee,
      'sports': sports,
      'requirements': requirements,
      'registeredUsers': registeredUsers,
      'interestedUsers': interestedUsers,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory EventModel.fromFirestore(Map<String, dynamic> data) {
    return EventModel(
      id: data['id'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      organizerId: data['organizerId'] as String,
      type: EventType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => EventType.other,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      location: data['location'] as String,
      imageUrl: data['imageUrl'] as String?,
      fee: data['fee'] as double?,
      sports: List<String>.from(data['sports'] ?? []),
      requirements: List<String>.from(data['requirements'] ?? []),
      registeredUsers: List<String>.from(data['registeredUsers'] ?? []),
      interestedUsers: List<String>.from(data['interestedUsers'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? organizerId,
    EventType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? imageUrl,
    double? fee,
    List<String>? sports,
    List<String>? requirements,
    List<String>? registeredUsers,
    List<String>? interestedUsers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      organizerId: organizerId ?? this.organizerId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      fee: fee ?? this.fee,
      sports: sports ?? this.sports,
      requirements: requirements ?? this.requirements,
      registeredUsers: registeredUsers ?? this.registeredUsers,
      interestedUsers: interestedUsers ?? this.interestedUsers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 
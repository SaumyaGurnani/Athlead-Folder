import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { athlete, coach, organization }

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserType userType;
  final String? profileImage;
  final String? bio;
  final List<String> sports;
  final List<String> achievements;
  final List<String> certifications;
  final List<String> following;
  final List<String> followers;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    this.profileImage,
    this.bio,
    required this.sports,
    required this.achievements,
    required this.certifications,
    required this.following,
    required this.followers,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      userType: UserType.values.firstWhere(
        (e) => e.toString() == 'UserType.${data['userType']}',
        orElse: () => UserType.athlete,
      ),
      profileImage: data['profileImage'],
      bio: data['bio'],
      sports: List<String>.from(data['sports'] ?? []),
      achievements: List<String>.from(data['achievements'] ?? []),
      certifications: List<String>.from(data['certifications'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'userType': userType.toString().split('.').last,
      'profileImage': profileImage,
      'bio': bio,
      'sports': sports,
      'achievements': achievements,
      'certifications': certifications,
      'following': following,
      'followers': followers,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserType? userType,
    String? profileImage,
    String? bio,
    List<String>? sports,
    List<String>? achievements,
    List<String>? certifications,
    List<String>? following,
    List<String>? followers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      sports: sports ?? this.sports,
      achievements: achievements ?? this.achievements,
      certifications: certifications ?? this.certifications,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 
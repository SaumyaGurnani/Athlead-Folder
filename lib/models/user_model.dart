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
    
    // Helper function to safely convert list data
    List<String> safeListConversion(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    // Helper function to safely convert timestamp
    DateTime safeTimestampConversion(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    // Helper function to safely convert user type
    UserType safeUserTypeConversion(dynamic value) {
      if (value == null) return UserType.athlete;
      final typeStr = value.toString().toLowerCase();
      return UserType.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == typeStr,
        orElse: () => UserType.athlete,
      );
    }

    return UserModel(
      id: doc.id,
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      userType: safeUserTypeConversion(data['userType']),
      profileImage: data['profileImage']?.toString(),
      bio: data['bio']?.toString(),
      sports: safeListConversion(data['sports']),
      achievements: safeListConversion(data['achievements']),
      certifications: safeListConversion(data['certifications']),
      following: safeListConversion(data['following']),
      followers: safeListConversion(data['followers']),
      createdAt: safeTimestampConversion(data['createdAt']),
      updatedAt: safeTimestampConversion(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'userType': userType.toString().split('.').last.toLowerCase(),
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
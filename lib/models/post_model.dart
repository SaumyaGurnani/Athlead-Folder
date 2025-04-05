import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String content;
  final List<String> images;
  final List<String> likes;
  final List<Comment> comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.images,
    required this.likes,
    required this.comments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Helper function to safely convert timestamp
    DateTime safeTimestampConversion(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return PostModel(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      images: List<String>.from(data['images'] ?? []),
      likes: List<String>.from(data['likes'] ?? []),
      comments: (data['comments'] as List<dynamic>?)
              ?.map((comment) => Comment.fromMap(comment as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: safeTimestampConversion(data['createdAt']),
      updatedAt: safeTimestampConversion(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'content': content,
      'images': images,
      'likes': likes,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? content,
    List<String>? images,
    List<String>? likes,
    List<Comment>? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      images: images ?? this.images,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Comment {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    // Helper function to safely convert timestamp
    DateTime safeTimestampConversion(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return Comment(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      createdAt: safeTimestampConversion(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
} 
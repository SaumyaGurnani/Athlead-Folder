import 'package:cloud_firestore/cloud_firestore.dart';

class PostComment {
  final String id;
  final String userId;
  final String content;
  final DateTime timestamp;

  const PostComment({
    required this.id,
    required this.userId,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory PostComment.fromFirestore(Map<String, dynamic> data) {
    return PostComment(
      id: data['id'] as String,
      userId: data['userId'] as String,
      content: data['content'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      content: json['content'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  PostComment copyWith({
    String? id,
    String? userId,
    String? content,
    DateTime? timestamp,
  }) {
    return PostComment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class PostModel {
  final String id;
  final String userId;
  final String content;
  final List<String> imageUrls;
  final List<String> likes;
  final List<PostComment> comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PostModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.imageUrls,
    required this.likes,
    required this.comments,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'imageUrls': imageUrls,
      'likes': likes,
      'comments': comments.map((comment) => comment.toFirestore()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PostModel.fromFirestore(Map<String, dynamic> data) {
    return PostModel(
      id: data['id'] as String,
      userId: data['userId'] as String,
      content: data['content'] as String,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      likes: List<String>.from(data['likes'] ?? []),
      comments: (data['comments'] as List<dynamic>?)
              ?.map((comment) => PostComment.fromFirestore(comment as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? content,
    List<String>? imageUrls,
    List<String>? likes,
    List<PostComment>? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';

/// Service class for handling post-related operations with Firebase.
class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Returns a stream of posts ordered by creation date.
  Stream<List<PostModel>> getFeedPosts(String userId) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc.data()))
            .toList());
  }

  /// Creates a new post with optional images.
  /// 
  /// Throws [FirebaseException] if the operation fails.
  Future<void> createPost({
    required String userId,
    required String content,
    List<File>? imageFiles,
  }) async {
    try {
      final List<String> imageUrls = [];

      if (imageFiles != null) {
        for (final file in imageFiles) {
          final ref = _storage
              .ref()
              .child('posts/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}');
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          imageUrls.add(url);
        }
      }

      final post = PostModel(
        id: _uuid.v4(),
        userId: userId,
        content: content,
        imageUrls: imageUrls,
        likes: [],
        comments: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('posts').doc(post.id).set(post.toFirestore());
    } catch (e) {
      throw FirebaseException(
        plugin: 'post_service',
        code: 'create_post_failed',
        message: 'Failed to create post: ${e.toString()}',
      );
    }
  }

  /// Adds a like to a post.
  /// 
  /// Throws [FirebaseException] if the operation fails.
  Future<void> likePost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      await postRef.update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw FirebaseException(
        plugin: 'post_service',
        code: 'like_post_failed',
        message: 'Failed to like post: ${e.toString()}',
      );
    }
  }

  /// Removes a like from a post.
  /// 
  /// Throws [FirebaseException] if the operation fails.
  Future<void> unlikePost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      await postRef.update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw FirebaseException(
        plugin: 'post_service',
        code: 'unlike_post_failed',
        message: 'Failed to unlike post: ${e.toString()}',
      );
    }
  }

  /// Adds a comment to a post.
  /// 
  /// Throws [FirebaseException] if the operation fails.
  Future<void> addComment(String postId, PostComment comment) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      await postRef.update({
        'comments': FieldValue.arrayUnion([comment.toFirestore()]),
      });
    } catch (e) {
      throw FirebaseException(
        plugin: 'post_service',
        code: 'add_comment_failed',
        message: 'Failed to add comment: ${e.toString()}',
      );
    }
  }

  /// Deletes a post and its associated images.
  /// 
  /// Throws [FirebaseException] if the operation fails.
  Future<void> deletePost(String postId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final post = await postRef.get();
      
      if (!post.exists) {
        throw FirebaseException(
          plugin: 'post_service',
          code: 'post_not_found',
          message: 'Post not found',
        );
      }

      final postData = PostModel.fromFirestore(post.data()!);
      
      // Delete images from storage
      for (final imageUrl in postData.imageUrls) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print('Error deleting image: $e');
        }
      }

      await postRef.delete();
    } catch (e) {
      throw FirebaseException(
        plugin: 'post_service',
        code: 'delete_post_failed',
        message: 'Failed to delete post: ${e.toString()}',
      );
    }
  }

  /// Updates an existing post.
  /// 
  /// Throws [FirebaseException] if the operation fails.
  Future<void> updatePost(PostModel post) async {
    try {
      final postRef = _firestore.collection('posts').doc(post.id);
      await postRef.update(post.toFirestore());
    } catch (e) {
      throw FirebaseException(
        plugin: 'post_service',
        code: 'update_post_failed',
        message: 'Failed to update post: ${e.toString()}',
      );
    }
  }
} 
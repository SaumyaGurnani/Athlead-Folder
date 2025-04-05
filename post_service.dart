import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new post
  Future<PostModel> createPost({
    required String userId,
    required String content,
    List<File>? imageFiles,
  }) async {
    try {
      List<String> imageUrls = [];
      if (imageFiles != null) {
        for (var file in imageFiles) {
          final ref = _storage.ref().child('posts/${DateTime.now().millisecondsSinceEpoch}.jpg');
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          imageUrls.add(url);
        }
      }

      final post = PostModel(
        id: '',
        userId: userId,
        content: content,
        imageUrls: imageUrls,
        likes: [],
        comments: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('posts').add(post.toFirestore());
      return post.copyWith(id: docRef.id);
    } catch (e) {
      rethrow;
    }
  }

  // Get posts for feed
  Stream<List<PostModel>> getFeedPosts(String userId) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromFirestore(doc.data())).toList());
  }

  // Get user's posts
  Stream<List<PostModel>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromFirestore(doc.data())).toList());
  }

  // Like a post
  Future<void> likePost(String postId, String userId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Add a comment
  Future<void> addComment(String postId, PostComment comment) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.arrayUnion([comment.toJson()]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      final post = await _firestore.collection('posts').doc(postId).get();
      final postData = PostModel.fromFirestore(post.data()!);

      // Delete images from storage
      for (var imageUrl in postData.imageUrls) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          // Ignore errors if image doesn't exist
        }
      }

      // Delete post document
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Update post
  Future<void> updatePost(PostModel post) async {
    try {
      await _firestore.collection('posts').doc(post.id).update(post.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // Get post by ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      return doc.exists ? PostModel.fromFirestore(doc.data()!) : null;
    } catch (e) {
      rethrow;
    }
  }
} 
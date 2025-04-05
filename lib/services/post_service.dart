import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  StreamSubscription? _feedSubscription;
  StreamSubscription? _userPostsSubscription;

  // Create post
  Future<void> createPost({
    required String userId,
    required String content,
    List<File>? imageFiles,
  }) async {
    try {
      List<String> imageUrls = [];

      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (var file in imageFiles) {
          final ref = _storage.ref().child('post_images/${DateTime.now().millisecondsSinceEpoch}_${imageUrls.length}.jpg');
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          imageUrls.add(url);
        }
      }

      final post = PostModel(
        id: '',
        userId: userId,
        content: content,
        images: imageUrls,
        likes: [],
        comments: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('posts').add(post.toFirestore());
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // Get feed posts with reconnection logic
  Stream<List<PostModel>> getFeedPosts(String userId) {
    // Cancel existing subscription if any
    _feedSubscription?.cancel();
    
    final controller = StreamController<List<PostModel>>();
    
    _feedSubscription = _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              final posts = snapshot.docs
                  .map((doc) => PostModel.fromFirestore(doc))
                  .toList();
              controller.add(posts);
            } catch (e) {
              print('Error converting feed posts: $e');
              controller.add([]);
            }
          },
          onError: (error) {
            print('Error in feed posts stream: $error');
            controller.add([]);
            // Attempt to reconnect after a delay
            Future.delayed(const Duration(seconds: 5), () {
              getFeedPosts(userId);
            });
          },
        );

    return controller.stream;
  }

  // Get user posts with reconnection logic
  Stream<List<PostModel>> getUserPosts(String userId) {
    // Cancel existing subscription if any
    _userPostsSubscription?.cancel();
    
    final controller = StreamController<List<PostModel>>();
    
    _userPostsSubscription = _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              final posts = snapshot.docs
                  .map((doc) => PostModel.fromFirestore(doc))
                  .toList();
              controller.add(posts);
            } catch (e) {
              print('Error converting user posts: $e');
              controller.add([]);
            }
          },
          onError: (error) {
            print('Error in user posts stream: $error');
            controller.add([]);
            // Attempt to reconnect after a delay
            Future.delayed(const Duration(seconds: 5), () {
              getUserPosts(userId);
            });
          },
        );

    return controller.stream;
  }

  // Dispose method to clean up subscriptions
  void dispose() {
    _feedSubscription?.cancel();
    _userPostsSubscription?.cancel();
  }

  // Like post
  Future<void> likePost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final post = await postRef.get();
      
      if (!post.exists) {
        throw Exception('Post not found');
      }

      final postData = post.data() as Map<String, dynamic>;
      final likes = List<String>.from(postData['likes'] ?? []);

      if (likes.contains(userId)) {
        throw Exception('Post already liked');
      }

      await postRef.update({
        'likes': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  // Unlike post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final post = await postRef.get();
      
      if (!post.exists) {
        throw Exception('Post not found');
      }

      final postData = post.data() as Map<String, dynamic>;
      final likes = List<String>.from(postData['likes'] ?? []);

      if (!likes.contains(userId)) {
        throw Exception('Post not liked');
      }

      await postRef.update({
        'likes': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to unlike post: $e');
    }
  }

  // Add comment
  Future<void> addComment(String postId, Comment comment) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final post = await postRef.get();
      
      if (!post.exists) {
        throw Exception('Post not found');
      }

      await postRef.update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final post = await postRef.get();
      
      if (!post.exists) {
        throw Exception('Post not found');
      }

      final postData = post.data() as Map<String, dynamic>;
      final images = List<String>.from(postData['images'] ?? []);

      // Delete images from storage
      for (var imageUrl in images) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          print('Failed to delete image: $e');
        }
      }

      await postRef.delete();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Get post by ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      if (!doc.exists) return null;
      return PostModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get post: $e');
    }
  }

  // Update post
  Future<void> updatePost(PostModel post) async {
    try {
      await _firestore.collection('posts').doc(post.id).update(post.toFirestore());
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }
} 
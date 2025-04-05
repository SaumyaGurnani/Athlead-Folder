import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

/// Provider class for managing post-related state and operations.
class PostProvider with ChangeNotifier {
  final PostService _postService = PostService();
  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _error;

  /// Returns the list of posts.
  List<PostModel> get posts => List.unmodifiable(_posts);
  
  /// Returns whether the provider is currently loading.
  bool get isLoading => _isLoading;
  
  /// Returns the current error message, if any.
  String? get error => _error;

  /// Returns a stream of posts for the feed.
  Stream<List<PostModel>> getFeedPosts(String userId) {
    return _postService.getFeedPosts(userId);
  }

  /// Creates a new post.
  /// 
  /// Sets [isLoading] to true while the operation is in progress.
  /// Sets [error] if the operation fails.
  Future<void> createPost({
    required String userId,
    required String content,
    List<File>? imageFiles,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _postService.createPost(
        userId: userId,
        content: content,
        imageFiles: imageFiles,
      );

      _isLoading = false;
      notifyListeners();
    } on FirebaseException catch (e) {
      _isLoading = false;
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'An unexpected error occurred: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Likes a post.
  /// 
  /// Sets [error] if the operation fails.
  Future<void> likePost(String postId, String userId) async {
    try {
      _error = null;
      await _postService.likePost(postId, userId);
      notifyListeners();
    } on FirebaseException catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = 'An unexpected error occurred: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Unlikes a post.
  /// 
  /// Sets [error] if the operation fails.
  Future<void> unlikePost(String postId, String userId) async {
    try {
      _error = null;
      await _postService.unlikePost(postId, userId);
      notifyListeners();
    } on FirebaseException catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = 'An unexpected error occurred: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Adds a comment to a post.
  /// 
  /// Sets [error] if the operation fails.
  Future<void> addComment(String postId, PostComment comment) async {
    try {
      _error = null;
      await _postService.addComment(postId, comment);
      notifyListeners();
    } on FirebaseException catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = 'An unexpected error occurred: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Deletes a post.
  /// 
  /// Sets [isLoading] to true while the operation is in progress.
  /// Sets [error] if the operation fails.
  Future<void> deletePost(String postId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _postService.deletePost(postId);

      _isLoading = false;
      notifyListeners();
    } on FirebaseException catch (e) {
      _isLoading = false;
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'An unexpected error occurred: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Updates an existing post.
  /// 
  /// Sets [isLoading] to true while the operation is in progress.
  /// Sets [error] if the operation fails.
  Future<void> updatePost(PostModel post) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _postService.updatePost(post);

      _isLoading = false;
      notifyListeners();
    } on FirebaseException catch (e) {
      _isLoading = false;
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'An unexpected error occurred: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Clears the current error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 
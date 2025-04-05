import 'dart:io';
import 'package:flutter/material.dart';
import 'models/post_model.dart';
import 'services/post_service.dart';

class PostProvider extends ChangeNotifier {
  final PostService _postService = PostService();
  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _error;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize feed
  void initializeFeed(String userId) {
    _postService.getFeedPosts(userId).listen(
      (posts) {
        _posts = posts;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Create post
  Future<void> createPost({
    required String userId,
    required String content,
    List<File>? imageFiles,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _postService.createPost(
        userId: userId,
        content: content,
        imageFiles: imageFiles,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Like post
  Future<void> likePost(String postId, String userId) async {
    try {
      await _postService.likePost(postId, userId);
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          likes: [..._posts[index].likes, userId],
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Unlike post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _postService.unlikePost(postId, userId);
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          likes: _posts[index].likes.where((id) => id != userId).toList(),
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Add comment
  Future<void> addComment(String postId, PostComment comment) async {
    try {
      await _postService.addComment(postId, comment);
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          comments: [..._posts[index].comments, comment],
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    try {
      await _postService.deletePost(postId);
      _posts.removeWhere((post) => post.id == postId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update post
  Future<void> updatePost(PostModel post) async {
    try {
      await _postService.updatePost(post);
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = post;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 
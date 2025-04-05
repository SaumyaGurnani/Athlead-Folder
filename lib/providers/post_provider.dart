import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

class PostProvider extends ChangeNotifier {
  final PostService _postService = PostService();
  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<PostModel>>? _feedSubscription;
  StreamSubscription<List<PostModel>>? _userPostsSubscription;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize feed
  void initializeFeed(String userId) {
    // Cancel existing subscription if any
    _feedSubscription?.cancel();
    
    _feedSubscription = _postService.getFeedPosts(userId).listen(
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

  // Get user posts
  Stream<List<PostModel>> getUserPosts(String userId) {
    // Cancel existing subscription if any
    _userPostsSubscription?.cancel();
    
    return _postService.getUserPosts(userId);
  }

  // Create post
  Future<void> createPost({
    required String userId,
    required String content,
    List<File>? imageFiles,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _postService.createPost(
        userId: userId,
        content: content,
        imageFiles: imageFiles,
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Like post
  Future<void> likePost(String postId, String userId) async {
    _clearError();
    try {
      await _postService.likePost(postId, userId);
      _updatePostLikes(postId, userId, true);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Unlike post
  Future<void> unlikePost(String postId, String userId) async {
    _clearError();
    try {
      await _postService.unlikePost(postId, userId);
      _updatePostLikes(postId, userId, false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Add comment
  Future<void> addComment(String postId, Comment comment) async {
    _clearError();
    try {
      await _postService.addComment(postId, comment);
      _updatePostComments(postId, comment);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    _setLoading(true);
    _clearError();

    try {
      await _postService.deletePost(postId);
      _posts.removeWhere((post) => post.id == postId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Share post
  Future<void> sharePost(String postId, String userId) async {
    _clearError();
    try {
      final post = await _postService.getPostById(postId);
      if (post != null) {
        // Create a new post with reference to the original
        await createPost(
          userId: userId,
          content: 'Shared post: ${post.content}',
          imageFiles: null,
        );
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _updatePostLikes(String postId, String userId, bool isLiked) {
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final post = _posts[index];
      final updatedLikes = isLiked
          ? [...post.likes, userId]
          : post.likes.where((id) => id != userId).toList();
      
      _posts[index] = post.copyWith(likes: updatedLikes);
      notifyListeners();
    }
  }

  void _updatePostComments(String postId, Comment comment) {
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = post.copyWith(
        comments: [...post.comments, comment],
      );
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _feedSubscription?.cancel();
    _postService.dispose();
    super.dispose();
  }
} 
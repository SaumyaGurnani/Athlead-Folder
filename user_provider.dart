import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProvider() {
    _initializeUser();
  }

  void _initializeUser() {
    _userService.getCurrentUser().listen(
      (user) {
        _currentUser = user;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required UserType userType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _userService.createUser(
        email: email,
        password: password,
        name: name,
        userType: userType,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userService.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> followUser(String targetUserId) async {
    if (_currentUser == null) return;

    try {
      await _userService.followUser(_currentUser!.id, targetUserId);
      _currentUser = _currentUser!.copyWith(
        following: [..._currentUser!.following, targetUserId],
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> unfollowUser(String targetUserId) async {
    if (_currentUser == null) return;

    try {
      await _userService.unfollowUser(_currentUser!.id, targetUserId);
      _currentUser = _currentUser!.copyWith(
        following: _currentUser!.following
            .where((id) => id != targetUserId)
            .toList(),
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addAchievement(String achievement) async {
    if (_currentUser == null) return;

    try {
      await _userService.addAchievement(_currentUser!.id, achievement);
      _currentUser = _currentUser!.copyWith(
        achievements: [..._currentUser!.achievements, achievement],
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addCertification(String certification) async {
    if (_currentUser == null) return;

    try {
      await _userService.addCertification(_currentUser!.id, certification);
      _currentUser = _currentUser!.copyWith(
        certifications: [..._currentUser!.certifications, certification],
      );
      notifyListeners();
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
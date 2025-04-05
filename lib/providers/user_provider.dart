import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  UserProvider() {
    _initializeAuthState();
  }

  void _initializeAuthState() {
    _userService.authStateChanges.listen((User? user) async {
      if (user == null) {
        _currentUser = null;
        notifyListeners();
      } else {
        try {
          _setLoading(true);
          final userDoc = await _userService.getUserById(user.uid);
          
          if (userDoc == null) {
            // If user document doesn't exist, create it
            _currentUser = await _userService.signIn(
              email: user.email ?? '',
              password: '', // We don't need the password here as the user is already authenticated
            );
          } else {
            _currentUser = userDoc;
          }
          notifyListeners();
        } catch (e) {
          _error = e.toString();
          notifyListeners();
        } finally {
          _setLoading(false);
        }
      }
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required UserType userType,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _userService.createUser(
        email: email,
        password: password,
        name: name,
        userType: userType,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _userService.signIn(
        email: email,
        password: password,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _userService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? profileImage,
    List<String>? sports,
    List<String>? achievements,
    List<String>? certifications,
  }) async {
    if (_currentUser == null) return;

    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _userService.updateUser(
        _currentUser!.id,
        name: name,
        bio: bio,
        profileImage: profileImage,
        sports: sports,
        achievements: achievements,
        certifications: certifications,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUserData() async {
    if (_currentUser == null) return;
    
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _userService.getUserById(_currentUser!.id);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
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
} 
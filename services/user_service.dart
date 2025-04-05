import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mock implementation - in a real app, this would get the current user from Firebase Auth
  Stream<UserModel?> getCurrentUser() {
    // Mock implementation - returns null for now
    return Stream.value(null);
  }

  Future<UserModel> createUser({
    required String email,
    required String password,
    required String name,
    required UserType userType,
  }) async {
    // Mock implementation - in a real app, this would create a user in Firebase Auth and Firestore
    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
      userType: userType,
      sports: [],
      achievements: [],
      certifications: [],
      following: [],
      followers: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.id).set(user.toFirestore());
    return user;
  }

  Future<void> updateUserProfile(UserModel user) async {
    // Mock implementation - in a real app, this would update the user in Firestore
    await _firestore.collection('users').doc(user.id).update(user.toFirestore());
  }

  Future<void> followUser(String userId, String targetUserId) async {
    // Mock implementation - in a real app, this would update both users in Firestore
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> unfollowUser(String userId, String targetUserId) async {
    // Mock implementation - in a real app, this would update both users in Firestore
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> addAchievement(String userId, String achievement) async {
    // Mock implementation - in a real app, this would update the user in Firestore
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> addCertification(String userId, String certification) async {
    // Mock implementation - in a real app, this would update the user in Firestore
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!doc.exists) {
        throw Exception('User data not found');
      }

      return UserModel.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }
}
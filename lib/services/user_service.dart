import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Cache duration in milliseconds (5 minutes)
  static const int _cacheDuration = 5 * 60 * 1000;
  
  // Cache for user data
  final Map<String, _CachedUserData> _userCache = {};

  // Get current user data
  Stream<UserModel?> getCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Sign in user
  Future<UserModel> signIn({
    required String email,
    String? password,
  }) async {
    try {
      User? firebaseUser;
      
      if (password != null && password.isNotEmpty) {
        // Sign in with email and password if provided
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        firebaseUser = userCredential.user;
      } else {
        // Get current user if already authenticated
        firebaseUser = _auth.currentUser;
      }

      if (firebaseUser == null) {
        throw Exception('No authenticated user found');
      }

      // Get user data from Firestore
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (!doc.exists) {
        // If user document doesn't exist, create it
        final user = UserModel(
          id: firebaseUser.uid,
          email: email,
          name: firebaseUser.displayName ?? email.split('@')[0],
          userType: UserType.athlete,
          profileImage: null,
          bio: null,
          sports: [],
          achievements: [],
          certifications: [],
          following: [],
          followers: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.id).set(user.toFirestore());
        _updateCache(user);
        return user;
      }

      // If user document exists, convert and return it
      final user = UserModel.fromFirestore(doc);
      _updateCache(user);
      return user;
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  // Create new user
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String name,
    required UserType userType,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      final user = UserModel(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        userType: userType,
        profileImage: null,
        bio: null,
        sports: [],
        achievements: [],
        certifications: [],
        following: [],
        followers: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Convert to Firestore format and set the document
      final userData = user.toFirestore();
      await _firestore.collection('users').doc(user.id).set(userData);
      
      // Update cache
      _updateCache(user);
      return user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw Exception('The password provided is too weak.');
        case 'email-already-in-use':
          throw Exception('An account already exists for that email.');
        case 'invalid-email':
          throw Exception('The email address is not valid.');
        default:
          throw Exception('An error occurred during sign up: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Follow user
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();
      
      // Add to following list
      batch.update(
        _firestore.collection('users').doc(currentUserId),
        {
          'following': FieldValue.arrayUnion([targetUserId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      
      // Add to followers list
      batch.update(
        _firestore.collection('users').doc(targetUserId),
        {
          'followers': FieldValue.arrayUnion([currentUserId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      
      await batch.commit();
      
      // Update cache for both users
      _invalidateCache(currentUserId);
      _invalidateCache(targetUserId);
    } catch (e) {
      rethrow;
    }
  }

  // Unfollow user
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      final batch = _firestore.batch();
      
      // Remove from following list
      batch.update(
        _firestore.collection('users').doc(currentUserId),
        {
          'following': FieldValue.arrayRemove([targetUserId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      
      // Remove from followers list
      batch.update(
        _firestore.collection('users').doc(targetUserId),
        {
          'followers': FieldValue.arrayRemove([currentUserId]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      
      await batch.commit();
      
      // Update cache for both users
      _invalidateCache(currentUserId);
      _invalidateCache(targetUserId);
    } catch (e) {
      rethrow;
    }
  }

  // Search users
  Stream<List<UserModel>> searchUsers(String query) {
    return _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    // Check cache first
    final cachedData = _userCache[userId];
    if (cachedData != null && 
        DateTime.now().difference(cachedData.timestamp).inMilliseconds < _cacheDuration) {
      return cachedData.user;
    }

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      final user = UserModel.fromFirestore(doc);
      _updateCache(user);
      return user;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Add achievement
  Future<void> addAchievement(String userId, String achievement) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'achievements': FieldValue.arrayUnion([achievement]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _invalidateCache(userId);
    } catch (e) {
      throw Exception('Failed to add achievement: $e');
    }
  }

  // Add certification
  Future<void> addCertification(String userId, String certification) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'certifications': FieldValue.arrayUnion([certification]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _invalidateCache(userId);
    } catch (e) {
      throw Exception('Failed to add certification: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userCache.clear(); // Clear cache on sign out
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  Future<UserModel> updateUser(
    String userId, {
    String? name,
    String? bio,
    String? profileImage,
    List<String>? sports,
    List<String>? achievements,
    List<String>? certifications,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        if (bio != null) 'bio': bio,
        if (profileImage != null) 'profileImage': profileImage,
        if (sports != null) 'sports': sports,
        if (achievements != null) 'achievements': achievements,
        if (certifications != null) 'certifications': certifications,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).update(updates);
      
      // Get updated user data
      final updatedUser = await getUserById(userId);
      if (updatedUser == null) {
        throw Exception('Failed to get updated user data');
      }
      _updateCache(updatedUser);
      return updatedUser;
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  void _updateCache(UserModel user) {
    _userCache[user.id] = _CachedUserData(user, DateTime.now());
  }

  void _invalidateCache(String userId) {
    _userCache.remove(userId);
  }
}

class _CachedUserData {
  final UserModel user;
  final DateTime timestamp;

  _CachedUserData(this.user, this.timestamp);
} 
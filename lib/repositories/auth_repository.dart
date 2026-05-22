import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../services/hive_service.dart';
import '../models/user_model.dart';
import '../core/constants/firestore_constants.dart';
import '../core/errors/exceptions.dart';

/// Auth repository
class AuthRepository {
  final AuthService _authService = AuthService();
  final SupabaseService _dbService = SupabaseService();

  User? get currentUser => _authService.currentUser;
  String? get currentUid => _authService.currentUid;
  bool get isSignedIn => _authService.isSignedIn;
  Stream<AuthState> get authStateChanges => _authService.authStateChanges;

  Future<void> signInWithEmailPassword(String emailOrUsername, String password) async {
    String email = emailOrUsername.trim();
    if (!email.contains('@')) {
      // Lookup username to get email
      final response = await _dbService.db
          .from(FirestoreConstants.usersCollection)
          .select('email')
          .eq('username', email)
          .maybeSingle();
      if (response == null) {
        throw AppAuthException('Username "$emailOrUsername" not found.');
      }
      email = response['email']?.toString() ?? '';
      if (email.isEmpty) {
        throw AppAuthException('Username has no email registered.');
      }
    }
    await _authService.signInWithEmailPassword(email, password);
  }

  Future<void> signUpWithEmailPassword(String email, String password, String username) async {
    // Unique usernames check
    final check = await _dbService.db
        .from(FirestoreConstants.usersCollection)
        .select('id')
        .eq('username', username.trim())
        .maybeSingle();
    if (check != null) {
      throw AppAuthException('Username "$username" is already taken. Please choose another.');
    }
    await _authService.signUpWithEmailPassword(email, password, username);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  Future<void> resetPassword(String newPassword) async {
    await _authService.resetPassword(newPassword);
  }

  /// Automatically trigger profile creation/update via authStateChanges in Provider
  Future<UserModel> createOrUpdateUser(User user) async {
    final uid = user.id;

    final existingData = await _dbService.getRow(
      table: FirestoreConstants.usersCollection,
      id: uid,
    );

    if (existingData != null) {
      final userModel = UserModel.fromMap(existingData);
      
      // Update basic fields if they changed
      final updatedModel = userModel.copyWith(
        email: user.email ?? userModel.email,
        username: user.userMetadata?['username'] ?? userModel.username,
        photoUrl: user.userMetadata?['avatar_url'] ?? userModel.photoUrl,
        isOnline: true,
        lastSeen: DateTime.now(),
      );

      await _dbService.updateRow(
        table: FirestoreConstants.usersCollection,
        id: uid,
        data: updatedModel.toDbMap(),
      );

      await HiveService.cacheUser(uid, updatedModel.toMap());
      return updatedModel;
    }

    // New user auto-creation
    final username = user.userMetadata?['username'] ?? user.email?.split('@')[0] ?? uid.substring(0, 8);
    
    final userModel = UserModel(
      uid: uid,
      displayName: username,
      username: username,
      email: user.email ?? '',
      photoUrl: user.userMetadata?['avatar_url'] ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isOnline: true,
      lastSeen: DateTime.now(),
    );

    try {
      await _dbService.insertRow(
        table: FirestoreConstants.usersCollection,
        data: userModel.toDbMap(),
      );
    } catch (e) {
      try {
        await _dbService.updateRow(
          table: FirestoreConstants.usersCollection,
          id: uid,
          data: userModel.toDbMap(),
        );
      } catch (_) {}
    }

    await HiveService.cacheUser(uid, userModel.toMap());
    return userModel;
  }

  Future<void> signOut() async {
    final uid = currentUid;
    if (uid != null) {
      try {
        await _dbService.updateRow(
          table: FirestoreConstants.usersCollection,
          id: uid,
          data: {
            'isOnline': false,
            'lastSeen': DateTime.now().toUtc().toIso8601String(),
          },
        );
      } catch (_) {}
    }

    await _authService.signOut();
    await HiveService.clearAll();
  }
}

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

  Future<void> signInWithGoogle() async {
    await _authService.signInWithGoogle();
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
      
      // Update basic fields if they changed via Google Profile
      final updatedModel = userModel.copyWith(
        email: user.email ?? userModel.email,
        displayName: user.userMetadata?['full_name'] ?? userModel.displayName,
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
    final userModel = UserModel(
      uid: uid,
      displayName: user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'User',
      username: '@${user.email?.split('@')[0] ?? uid.substring(0, 8)}',
      email: user.email ?? '',
      photoUrl: user.userMetadata?['avatar_url'] ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isOnline: true,
      lastSeen: DateTime.now(),
    );

    await _dbService.insertRow(
      table: FirestoreConstants.usersCollection,
      data: userModel.toDbMap(),
    );

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

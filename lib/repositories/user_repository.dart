import '../services/supabase_service.dart';
import '../services/hive_service.dart';
import '../models/user_model.dart';
import '../core/constants/firestore_constants.dart';
import '../core/errors/exceptions.dart';

class UserRepository {
  final SupabaseService _dbService = SupabaseService();

  Future<UserModel?> getUser(String uid) async {
    try {
      final data = await _dbService.getRow(
        table: FirestoreConstants.usersCollection,
        id: uid,
      );

      if (data != null) {
        final user = UserModel.fromMap(data);
        await HiveService.cacheUser(uid, user.toMap());
        return user;
      }

      final cached = HiveService.getCachedUser(uid);
      if (cached != null) return UserModel.fromMap(cached);
      return null;
    } catch (e) {
      final cached = HiveService.getCachedUser(uid);
      if (cached != null) return UserModel.fromMap(cached);
      throw DatabaseException('Failed to get user', originalError: e);
    }
  }

  Stream<UserModel?> streamUser(String uid) {
    return _dbService
        .streamRow(table: FirestoreConstants.usersCollection, id: uid)
        .map((data) => data != null ? UserModel.fromMap(data) : null);
  }

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? username,
    String? bio,
    String? photoUrl,
  }) async {
    final data = <String, dynamic>{
      FirestoreConstants.updatedAt: DateTime.now().toUtc().toIso8601String(),
    };

    if (displayName != null) data[FirestoreConstants.displayName] = displayName;
    if (username != null) data[FirestoreConstants.username] = username;
    if (bio != null) data[FirestoreConstants.bio] = bio;
    if (photoUrl != null) data[FirestoreConstants.photoUrl] = photoUrl;

    await _dbService.updateRow(
      table: FirestoreConstants.usersCollection,
      id: uid,
      data: data,
    );
  }

  Future<void> setOnlineStatus(String uid, bool isOnline) async {
    await _dbService.updateRow(
      table: FirestoreConstants.usersCollection,
      id: uid,
      data: {
        FirestoreConstants.isOnline: isOnline,
        FirestoreConstants.lastSeen: DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _dbService.updateRow(
      table: FirestoreConstants.usersCollection,
      id: uid,
      data: {FirestoreConstants.fcmToken: token},
    );
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final currentUid = _dbService.client.auth.currentUser?.id;

    // Simple ilike search on Supabase across username, display_name, and email
    final response = await _dbService.db
        .from(FirestoreConstants.usersCollection)
        .select()
        .or('username.ilike.%$query%,display_name.ilike.%$query%,email.ilike.%$query%')
        .neq('id', currentUid ?? '') // Exclude current user
        .limit(20);

    return (response as List).map((e) => UserModel.fromMap(e)).toList();
  }

  Future<void> updatePrivacy({
    required String uid,
    bool? hideOnline,
    bool? hideLastSeen,
  }) async {
    final data = <String, dynamic>{};
    if (hideOnline != null) data[FirestoreConstants.hideOnline] = hideOnline;
    if (hideLastSeen != null) data[FirestoreConstants.hideLastSeen] = hideLastSeen;
    if (data.isNotEmpty) {
      await _dbService.updateRow(
        table: FirestoreConstants.usersCollection,
        id: uid,
        data: data,
      );
    }
  }

  // Blocking logic in Supabase could use arrays or a separate table.
  // Using an array of strings in JSONB or array column:
  Future<void> blockUser(String uid, String blockedUid) async {
    // Requires RPC or reading existing array and updating it.
    // Simplifying: read then update
    final user = await getUser(uid);
    if (user != null && !user.blockedUsers.contains(blockedUid)) {
      final blocked = List<String>.from(user.blockedUsers)..add(blockedUid);
      await _dbService.updateRow(
        table: FirestoreConstants.usersCollection,
        id: uid,
        data: {FirestoreConstants.blockedUsers: blocked},
      );
    }
  }

  Future<void> unblockUser(String uid, String blockedUid) async {
    final user = await getUser(uid);
    if (user != null && user.blockedUsers.contains(blockedUid)) {
      final blocked = List<String>.from(user.blockedUsers)..remove(blockedUid);
      await _dbService.updateRow(
        table: FirestoreConstants.usersCollection,
        id: uid,
        data: {FirestoreConstants.blockedUsers: blocked},
      );
    }
  }

  Future<void> updateDarkMode(String uid, bool darkMode) async {
    await _dbService.updateRow(
      table: FirestoreConstants.usersCollection,
      id: uid,
      data: {FirestoreConstants.darkMode: darkMode},
    );
    await HiveService.setDarkMode(darkMode);
  }
}

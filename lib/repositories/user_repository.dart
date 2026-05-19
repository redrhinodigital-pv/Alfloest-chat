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
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };

    if (displayName != null) data['displayName'] = displayName;
    if (username != null) data['username'] = username;
    if (bio != null) data['bio'] = bio;
    if (photoUrl != null) data['photoUrl'] = photoUrl;

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
        'isOnline': isOnline,
        'lastSeen': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _dbService.updateRow(
      table: FirestoreConstants.usersCollection,
      id: uid,
      data: {'fcmToken': token},
    );
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    // Simple ilike search on Supabase
    final response = await _dbService.db
        .from(FirestoreConstants.usersCollection)
        .select()
        .or('username.ilike.%$query%,displayName.ilike.%$query%')
        .limit(20);

    return (response as List).map((e) => UserModel.fromMap(e)).toList();
  }

  Future<void> updatePrivacy({
    required String uid,
    bool? hideOnline,
    bool? hideLastSeen,
  }) async {
    final data = <String, dynamic>{};
    if (hideOnline != null) data['hideOnline'] = hideOnline;
    if (hideLastSeen != null) data['hideLastSeen'] = hideLastSeen;
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
        data: {'blockedUsers': blocked},
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
        data: {'blockedUsers': blocked},
      );
    }
  }

  Future<void> updateDarkMode(String uid, bool darkMode) async {
    await _dbService.updateRow(
      table: FirestoreConstants.usersCollection,
      id: uid,
      data: {'darkMode': darkMode},
    );
    await HiveService.setDarkMode(darkMode);
  }
}

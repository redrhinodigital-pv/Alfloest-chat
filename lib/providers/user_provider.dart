import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';

/// User repository provider
final userRepositoryProvider = Provider((ref) => UserRepository());

/// Stream current user's profile (realtime)
final currentUserProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return ref.watch(userRepositoryProvider).streamUser(uid);
});

/// Fetch a user by uid (one-time)
final userByIdProvider = FutureProvider.family<UserModel?, String>((ref, uid) {
  return ref.watch(userRepositoryProvider).getUser(uid);
});

/// Search users
final userSearchProvider = FutureProvider.family<List<UserModel>, String>((ref, query) {
  return ref.watch(userRepositoryProvider).searchUsers(query);
});

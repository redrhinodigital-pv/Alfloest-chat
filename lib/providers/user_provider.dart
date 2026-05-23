import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';
import '../services/presence_service.dart';
import 'auth_provider.dart';

/// User repository provider
final userRepositoryProvider = Provider((ref) => UserRepository());

/// Active online presence service provider
final presenceProvider = Provider<PresenceService?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return null;

  final userRepo = ref.read(userRepositoryProvider);
  final presenceService = PresenceService(uid: authState.uid, userRepo: userRepo);
  
  // Initialize lifecycle & socket listeners
  presenceService.init();

  ref.onDispose(() {
    presenceService.dispose();
  });

  return presenceService;
});

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

/// Stream any user's profile (realtime)
final userStreamProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return ref.watch(userRepositoryProvider).streamUser(uid);
});

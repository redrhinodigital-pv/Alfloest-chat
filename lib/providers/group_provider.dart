import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/group_repository.dart';
import '../models/group_model.dart';
import '../models/message_model.dart';

/// Group repository provider
final groupRepositoryProvider = Provider((ref) => GroupRepository());

/// Stream user's groups
final groupsProvider = StreamProvider.family<List<GroupModel>, String>((ref, uid) {
  return ref.watch(groupRepositoryProvider).streamGroups(uid);
});

/// Stream a single group
final groupProvider = StreamProvider.family<GroupModel?, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).streamGroup(groupId);
});

/// Stream group messages
final groupMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).streamGroupMessages(groupId);
});

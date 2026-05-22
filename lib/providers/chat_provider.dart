import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/chat_repository.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

/// Chat repository provider
final chatRepositoryProvider = Provider((ref) => ChatRepository());

/// Stream all chats for a user
final chatsProvider = StreamProvider.family<List<ChatModel>, String>((ref, uid) {
  ref.keepAlive();
  return ref.watch(chatRepositoryProvider).streamChats(uid);
});

/// Stream messages for a chat
final messagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  ref.keepAlive();
  return ref.watch(chatRepositoryProvider).streamMessages(chatId);
});

/// Stream a single chat
final chatProvider = StreamProvider.family<ChatModel?, String>((ref, chatId) {
  ref.keepAlive();
  return ref.watch(chatRepositoryProvider).streamChat(chatId);
});

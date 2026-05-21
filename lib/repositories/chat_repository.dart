import 'package:uuid/uuid.dart';
import '../services/supabase_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../core/constants/firestore_constants.dart';
import '../core/enums/enums.dart';

class ChatRepository {
  final SupabaseService _dbService = SupabaseService();
  final _uuid = const Uuid();

  Future<ChatModel> getOrCreateChat(String uid1, String uid2) async {
    // In Supabase, searching arrays can use `.contains()`
    final response = await _dbService.db
        .from(FirestoreConstants.chatsCollection)
        .select()
        .contains('participants', [uid1, uid2])
        .eq('type', ChatType.oneToOne.name)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      return ChatModel.fromMap(response);
    }

    final chatId = _uuid.v4();
    final chat = ChatModel(
      id: chatId,
      participants: [uid1, uid2],
      type: ChatType.oneToOne,
      createdAt: DateTime.now(),
    );

    await _dbService.insertRow(
      table: FirestoreConstants.chatsCollection,
      data: chat.toDbMap(),
    );

    return chat;
  }

  Stream<List<ChatModel>> streamChats(String uid) {
    return _dbService.db
        .from(FirestoreConstants.chatsCollection)
        .stream(primaryKey: ['id'])
        .order('lastMessageTime', ascending: false)
        .map((list) => list
            .where((c) => (c['participants'] as List).contains(uid))
            .map((e) => ChatModel.fromMap(e))
            .toList());
  }

  Stream<ChatModel?> streamChat(String chatId) {
    return _dbService.db
        .from(FirestoreConstants.chatsCollection)
        .stream(primaryKey: ['id'])
        .eq('id', chatId)
        .map((list) => list.isNotEmpty ? ChatModel.fromMap(list.first) : null);
  }

  Future<ChatModel?> getChat(String chatId) async {
    final data = await _dbService.getRow(table: FirestoreConstants.chatsCollection, id: chatId);
    if (data != null) return ChatModel.fromMap(data);
    return null;
  }

  Future<MessageModel> sendMessage({
    required String chatId, required String senderId, required String senderName,
    required String text, MessageType type = MessageType.text,
    String? replyTo, String? replyToText, String? replyToSender,
    String? forwardedFrom, String? voiceNoteUrl, int? voiceNoteDuration,
    String? mediaUrl, String? fileName, int? fileSize,
    List<String> mentions = const [],
  }) async {
    final msgId = _uuid.v4();
    final message = MessageModel(
      id: msgId, chatId: chatId, senderId: senderId, senderName: senderName, text: text,
      type: type, status: MessageStatus.sent, timestamp: DateTime.now(),
      replyTo: replyTo, replyToText: replyToText, replyToSender: replyToSender,
      forwardedFrom: forwardedFrom, voiceNoteUrl: voiceNoteUrl,
      voiceNoteDuration: voiceNoteDuration, mediaUrl: mediaUrl,
      fileName: fileName, fileSize: fileSize, mentions: mentions,
    );

    // No batch native in supabase_flutter like Firestore, just sequential or RPC
    await _dbService.insertRow(
      table: 'messages', // Assuming we map subcollections to a top-level messages table
      data: message.toDbMap(),
    );

    String lastMsgText = text;
    if (type == MessageType.voiceNote) {
      lastMsgText = '🎤 Voice note';
    } else if (type == MessageType.image) {
      lastMsgText = '📷 Photo';
    } else if (type == MessageType.video) {
      lastMsgText = '🎥 Video';
    } else if (type == MessageType.file) {
      lastMsgText = '📁 ${fileName ?? 'Document'}';
    }

    await _dbService.updateRow(
      table: FirestoreConstants.chatsCollection,
      id: chatId,
      data: {
        'lastMessage': lastMsgText,
        'lastMessageTime': DateTime.now().toUtc().toIso8601String(),
        'lastMessageSender': senderId,
      },
    );
    return message;
  }

  Stream<List<MessageModel>> streamMessages(String chatId, {int limit = 30}) {
    return _dbService.db
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chatId', chatId)
        .order('timestamp', ascending: false)
        .limit(limit)
        .map((list) => list.map((e) => MessageModel.fromMap(e)).toList());
  }

  Future<void> markAllAsSeen(String chatId, String currentUid) async {
    await _dbService.db
        .from('messages')
        .update({'status': MessageStatus.seen.name})
        .eq('chatId', chatId)
        .neq('senderId', currentUid)
        .neq('status', MessageStatus.seen.name);
    
    // Simplification for unreadCount reset
    final chat = await getChat(chatId);
    if (chat != null) {
      final unreads = Map<String, int>.from(chat.unreadCount);
      unreads[currentUid] = 0;
      await _dbService.updateRow(
        table: FirestoreConstants.chatsCollection,
        id: chatId,
        data: {'unreadCount': unreads},
      );
    }
  }

  Future<void> deleteForMe(String chatId, String messageId, String uid) async {
    // Fetch then update array
    final res = await _dbService.getRow(table: 'messages', id: messageId);
    if (res != null) {
      final deletedFor = List<String>.from(res['deletedFor'] ?? [])..add(uid);
      await _dbService.updateRow(table: 'messages', id: messageId, data: {'deletedFor': deletedFor});
    }
  }

  Future<void> deleteForEveryone(String chatId, String messageId) async {
    await _dbService.updateRow(table: 'messages', id: messageId, data: {'deletedForEveryone': true, 'text': ''});
  }

  Future<void> addReaction(String chatId, String messageId, String userId, String emoji) async {
    final res = await _dbService.getRow(table: 'messages', id: messageId);
    if (res != null) {
      final reactions = Map<String, String>.from(res['reactions'] ?? {});
      reactions[userId] = emoji;
      await _dbService.updateRow(table: 'messages', id: messageId, data: {'reactions': reactions});
    }
  }

  Future<void> removeReaction(String chatId, String messageId, String userId) async {
    final res = await _dbService.getRow(table: 'messages', id: messageId);
    if (res != null) {
      final reactions = Map<String, String>.from(res['reactions'] ?? {});
      reactions.remove(userId);
      await _dbService.updateRow(table: 'messages', id: messageId, data: {'reactions': reactions});
    }
  }

  Future<void> setTyping(String chatId, String uid, bool isTyping) async {
    final chat = await getChat(chatId);
    if (chat != null) {
      final typings = List<String>.from(chat.typingUsers);
      if (isTyping && !typings.contains(uid)) typings.add(uid);
      if (!isTyping) typings.remove(uid);
      await _dbService.updateRow(table: FirestoreConstants.chatsCollection, id: chatId, data: {'typingUsers': typings});
    }
  }

  Future<void> togglePin(String chatId, String uid, bool pin) async {
    final chat = await getChat(chatId);
    if (chat != null) {
      final pinnedBy = List<String>.from(chat.pinnedBy);
      if (pin && !pinnedBy.contains(uid)) pinnedBy.add(uid);
      if (!pin) pinnedBy.remove(uid);
      await _dbService.updateRow(table: FirestoreConstants.chatsCollection, id: chatId, data: {'pinnedBy': pinnedBy});
    }
  }

  Future<void> toggleArchive(String chatId, String uid, bool archive) async {
    final chat = await getChat(chatId);
    if (chat != null) {
      final archivedBy = List<String>.from(chat.archivedBy);
      if (archive && !archivedBy.contains(uid)) archivedBy.add(uid);
      if (!archive) archivedBy.remove(uid);
      await _dbService.updateRow(table: FirestoreConstants.chatsCollection, id: chatId, data: {'archivedBy': archivedBy});
    }
  }

  Future<void> toggleFavorite(String chatId, String uid, bool favorite) async {
    final chat = await getChat(chatId);
    if (chat != null) {
      final favoriteBy = List<String>.from(chat.favoriteBy);
      if (favorite && !favoriteBy.contains(uid)) favoriteBy.add(uid);
      if (!favorite) favoriteBy.remove(uid);
      await _dbService.updateRow(table: FirestoreConstants.chatsCollection, id: chatId, data: {'favoriteBy': favoriteBy});
    }
  }

  Future<void> clearChat(String chatId, String uid) async {
    try {
      final messages = await _dbService.db
          .from('messages')
          .select('id, deletedFor')
          .eq('chatId', chatId);
      
      for (final m in messages) {
        final id = m['id'];
        final deletedFor = List<String>.from(m['deletedFor'] ?? []);
        if (!deletedFor.contains(uid)) {
          deletedFor.add(uid);
          await _dbService.db.from('messages').update({'deletedFor': deletedFor}).eq('id', id);
        }
      }
    } catch (e) {
      // Ignore or log
    }
  }

  Future<void> deleteChat(String chatId, String uid) async {
    await clearChat(chatId, uid);
    await toggleArchive(chatId, uid, true);
  }

  Future<void> editMessage(String messageId, String newText) async {
    await _dbService.updateRow(
      table: 'messages',
      id: messageId,
      data: {'text': newText},
    );
  }
}

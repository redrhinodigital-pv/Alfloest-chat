import 'package:uuid/uuid.dart';
import '../services/supabase_service.dart';
import '../models/group_model.dart';
import '../models/message_model.dart';
import '../core/constants/firestore_constants.dart';
import '../core/enums/enums.dart';

class GroupRepository {
  final SupabaseService _dbService = SupabaseService();
  final _uuid = const Uuid();

  Future<GroupModel> createGroup({
    required String name,
    required String createdBy,
    String description = '',
    required List<String> members,
  }) async {
    final groupId = _uuid.v4();
    
    final allMembers = <String>{createdBy, ...members}.toList();

    final group = GroupModel(
      id: groupId,
      name: name,
      description: description,
      createdBy: createdBy,
      admins: [createdBy],
      members: allMembers,
      createdAt: DateTime.now(),
    );

    await _dbService.insertRow(
      table: FirestoreConstants.groupsCollection,
      data: group.toDbMap(),
    );

    return group;
  }

  Stream<List<GroupModel>> streamGroups(String uid) {
    return StreamUtils.retryStream(() => _dbService.db
        .from(FirestoreConstants.groupsCollection)
        .stream(primaryKey: ['id'])
        .order('lastMessageTime', ascending: false)
        .map((list) => list
            .where((g) => (g['members'] as List).contains(uid))
            .map((e) => GroupModel.fromMap(e))
            .toList()));
  }

  Stream<GroupModel?> streamGroup(String groupId) {
    return StreamUtils.retryStream(() => _dbService.db
        .from(FirestoreConstants.groupsCollection)
        .stream(primaryKey: ['id'])
        .eq('id', groupId)
        .map((list) => list.isNotEmpty ? GroupModel.fromMap(list.first) : null));
  }

  Future<GroupModel?> getGroup(String groupId) async {
    final data = await _dbService.getRow(table: FirestoreConstants.groupsCollection, id: groupId);
    if (data != null) return GroupModel.fromMap(data);
    return null;
  }

  Future<void> sendGroupMessage({
    required String groupId, required String senderId, required String senderName,
    required String text, MessageType type = MessageType.text,
    String? replyTo, String? replyToText, String? replyToSender,
    String? voiceNoteUrl, int? voiceNoteDuration,
    String? mediaUrl, String? fileName, int? fileSize,
    List<String> mentions = const [],
  }) async {
    final msgId = _uuid.v4();
    final message = MessageModel(
      id: msgId, chatId: groupId, senderId: senderId, senderName: senderName,
      text: text, type: type, status: MessageStatus.sent, timestamp: DateTime.now(),
      replyTo: replyTo, replyToText: replyToText, replyToSender: replyToSender,
      voiceNoteUrl: voiceNoteUrl, voiceNoteDuration: voiceNoteDuration,
      mediaUrl: mediaUrl, fileName: fileName, fileSize: fileSize,
      mentions: mentions,
    );

    await _dbService.insertRow(
      table: 'messages',
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
    } else if (type == MessageType.sticker) {
      lastMsgText = '👾 Sticker';
    } else if (type == MessageType.gif) {
      lastMsgText = '🎬 GIF';
    }

    await _dbService.updateRow(
      table: FirestoreConstants.groupsCollection,
      id: groupId,
      data: {
        'lastMessage': lastMsgText,
        'lastMessageTime': DateTime.now().toUtc().toIso8601String(),
        'lastMessageSender': senderName,
      },
    );
  }

  Stream<List<MessageModel>> streamGroupMessages(String groupId, {int limit = 30}) {
    return StreamUtils.retryStream(() => _dbService.db
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chatId', groupId)
        .order('timestamp', ascending: false)
        .limit(limit)
        .map((list) => list.map((e) => MessageModel.fromMap(e)).toList()));
  }

  Future<void> updateGroupDetails(String groupId, {String? name, String? description, String? groupImage}) async {
    final data = <String, dynamic>{};
    if (name != null) data['groupName'] = name;
    if (description != null) data['groupDescription'] = description;
    if (groupImage != null) data['groupImage'] = groupImage;
    
    if (data.isNotEmpty) {
      await _dbService.updateRow(table: FirestoreConstants.groupsCollection, id: groupId, data: data);
    }
  }

  Future<void> addMembers(String groupId, List<String> newMembers) async {
    final group = await getGroup(groupId);
    if (group != null) {
      final members = List<String>.from(group.members)..addAll(newMembers);
      await _dbService.updateRow(table: FirestoreConstants.groupsCollection, id: groupId, data: {'members': members.toSet().toList()});
    }
  }

  Future<void> removeMember(String groupId, String uid) async {
    final group = await getGroup(groupId);
    if (group != null) {
      final members = List<String>.from(group.members)..remove(uid);
      final admins = List<String>.from(group.admins)..remove(uid);
      await _dbService.updateRow(table: FirestoreConstants.groupsCollection, id: groupId, data: {'members': members, 'admins': admins});
    }
  }

  Future<void> makeAdmin(String groupId, String uid) async {
    final group = await getGroup(groupId);
    if (group != null && !group.admins.contains(uid)) {
      final admins = List<String>.from(group.admins)..add(uid);
      await _dbService.updateRow(table: FirestoreConstants.groupsCollection, id: groupId, data: {'admins': admins});
    }
  }

  Future<List<GroupModel>> getGroupsInCommon(String uid1, String uid2) async {
    try {
      final response = await _dbService.db
          .from(FirestoreConstants.groupsCollection)
          .select()
          .contains('members', [uid1, uid2]);
      return (response as List).map((e) => GroupModel.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> editGroupMessage(String messageId, String newText) async {
    await _dbService.updateRow(
      table: 'messages',
      id: messageId,
      data: {'text': newText},
    );
  }
}

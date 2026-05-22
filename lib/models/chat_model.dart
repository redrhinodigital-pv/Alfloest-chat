import '../core/enums/enums.dart';

/// Chat model — maps to Supabase `chats` table
class ChatModel {
  final String id;
  final List<String> participants;
  final ChatType type;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String lastMessageSender;
  final List<String> pinnedBy;
  final List<String> archivedBy;
  final List<String> favoriteBy;
  final List<String> mutedBy;
  final Map<String, int> unreadCount;
  final List<String> typingUsers;
  final DateTime createdAt;

  const ChatModel({
    required this.id,
    required this.participants,
    this.type = ChatType.oneToOne,
    this.lastMessage = '',
    this.lastMessageTime,
    this.lastMessageSender = '',
    this.pinnedBy = const [],
    this.archivedBy = const [],
    this.favoriteBy = const [],
    this.mutedBy = const [],
    this.unreadCount = const {},
    this.typingUsers = const [],
    required this.createdAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> data) {
    return ChatModel(
      id: data['id']?.toString() ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      type: ChatType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'oneToOne'),
        orElse: () => ChatType.oneToOne,
      ),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime'] != null
          ? DateTime.tryParse(data['lastMessageTime'].toString())?.toLocal()
          : null,
      lastMessageSender: data['lastMessageSender'] ?? '',
      pinnedBy: List<String>.from(data['pinnedBy'] ?? []),
      archivedBy: List<String>.from(data['archivedBy'] ?? []),
      favoriteBy: List<String>.from(data['favoriteBy'] ?? []),
      mutedBy: List<String>.from(data['mutedBy'] ?? []),
      unreadCount: data['unreadCount'] is Map 
          ? Map<String, int>.from(data['unreadCount'].map((key, value) => MapEntry(key.toString(), int.tryParse(value.toString()) ?? 0)))
          : {},
      typingUsers: List<String>.from(data['typingUsers'] ?? []),
      createdAt: data['createdAt'] != null 
          ? DateTime.tryParse(data['createdAt'].toString())?.toLocal() ?? DateTime.now() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'participants': participants,
      'type': type.name,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toUtc().toIso8601String(),
      'lastMessageSender': lastMessageSender,
      'pinnedBy': pinnedBy,
      'archivedBy': archivedBy,
      'favoriteBy': favoriteBy,
      'mutedBy': mutedBy,
      'unreadCount': unreadCount,
      'typingUsers': typingUsers,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  /// Get the other participant's uid in a 1-to-1 chat
  String otherParticipant(String currentUid) {
    return participants.firstWhere(
      (uid) => uid != currentUid,
      orElse: () => currentUid,
    );
  }

  /// Check if this chat is pinned by a specific user
  bool isPinnedBy(String uid) => pinnedBy.contains(uid);

  /// Check if this chat is archived by a specific user
  bool isArchivedBy(String uid) => archivedBy.contains(uid);

  /// Check if this chat is favorited by a specific user
  bool isFavoritedBy(String uid) => favoriteBy.contains(uid);

  /// Check if this chat is muted by a specific user
  bool isMutedBy(String uid) => mutedBy.contains(uid);

  /// Get unread count for a specific user
  int getUnreadCount(String uid) => unreadCount[uid] ?? 0;

  /// Check if someone is typing
  bool isTyping(String excludeUid) {
    return typingUsers.any((uid) => uid != excludeUid);
  }

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    ChatType? type,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSender,
    List<String>? pinnedBy,
    List<String>? archivedBy,
    List<String>? favoriteBy,
    List<String>? mutedBy,
    Map<String, int>? unreadCount,
    List<String>? typingUsers,
    DateTime? createdAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      type: type ?? this.type,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      archivedBy: archivedBy ?? this.archivedBy,
      favoriteBy: favoriteBy ?? this.favoriteBy,
      mutedBy: mutedBy ?? this.mutedBy,
      unreadCount: unreadCount ?? this.unreadCount,
      typingUsers: typingUsers ?? this.typingUsers,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

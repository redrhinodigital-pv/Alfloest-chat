/// Firestore collection and field name constants
class FirestoreConstants {
  FirestoreConstants._();

  // ── Collections ──
  static const String usersCollection = 'profiles';
  static const String chatsCollection = 'chats';
  static const String messagesSubcollection = 'messages';
  static const String groupsCollection = 'groups';
  static const String notificationsCollection = 'notifications';
  static const String itemsSubcollection = 'items';

  // ── User Fields ──
  static const String uid = 'uid';
  static const String displayName = 'displayName';
  static const String username = 'username';
  static const String email = 'email';
  static const String phone = 'phone';
  static const String photoUrl = 'photoUrl';
  static const String bio = 'bio';
  static const String isOnline = 'isOnline';
  static const String lastSeen = 'lastSeen';
  static const String darkMode = 'darkMode';
  static const String hideOnline = 'hideOnline';
  static const String hideLastSeen = 'hideLastSeen';
  static const String blockedUsers = 'blockedUsers';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String fcmToken = 'fcmToken';

  // ── Chat Fields ──
  static const String participants = 'participants';
  static const String chatType = 'type';
  static const String lastMessage = 'lastMessage';
  static const String lastMessageTime = 'lastMessageTime';
  static const String lastMessageSender = 'lastMessageSender';
  static const String pinnedBy = 'pinnedBy';
  static const String archivedBy = 'archivedBy';
  static const String unreadCount = 'unreadCount';
  static const String typingUsers = 'typingUsers';

  // ── Message Fields ──
  static const String senderId = 'senderId';
  static const String senderName = 'senderName';
  static const String text = 'text';
  static const String messageType = 'messageType';
  static const String timestamp = 'timestamp';
  static const String status = 'status';
  static const String replyTo = 'replyTo';
  static const String replyToText = 'replyToText';
  static const String replyToSender = 'replyToSender';
  static const String forwardedFrom = 'forwardedFrom';
  static const String deletedFor = 'deletedFor';
  static const String deletedForEveryone = 'deletedForEveryone';
  static const String reactions = 'reactions';
  static const String voiceNoteUrl = 'voiceNoteUrl';
  static const String voiceNoteDuration = 'voiceNoteDuration';
  static const String mentions = 'mentions';

  // ── Group Fields ──
  static const String groupName = 'groupName';
  static const String groupDescription = 'groupDescription';
  static const String groupCreatedBy = 'createdBy';
  static const String admins = 'admins';
  static const String members = 'members';

  // ── Notification Fields ──
  static const String notificationType = 'type';
  static const String title = 'title';
  static const String body = 'body';
  static const String data = 'data';
  static const String read = 'read';
}

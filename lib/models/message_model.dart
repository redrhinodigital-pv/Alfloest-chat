import '../core/enums/enums.dart';

/// Message model — maps to Supabase `messages` table
class MessageModel {
  final String id;
  final String chatId; // Added for Supabase flat table design
  final String senderId;
  final String senderName;
  final String text;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;

  // Reply
  final String? replyTo;
  final String? replyToText;
  final String? replyToSender;

  // Forward
  final String? forwardedFrom;

  // Delete
  final List<String> deletedFor;
  final bool deletedForEveryone;

  // Reactions
  final Map<String, String> reactions; // {userId: emoji}

  // Voice note
  final String? voiceNoteUrl;
  final int? voiceNoteDuration; // seconds

  // Mentions (for group chats)
  final List<String> mentions;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.text = '',
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.replyTo,
    this.replyToText,
    this.replyToSender,
    this.forwardedFrom,
    this.deletedFor = const [],
    this.deletedForEveryone = false,
    this.reactions = const {},
    this.voiceNoteUrl,
    this.voiceNoteDuration,
    this.mentions = const [],
  });

  factory MessageModel.fromMap(Map<String, dynamic> data) {
    return MessageModel(
      id: data['id']?.toString() ?? '',
      chatId: data['chatId']?.toString() ?? '',
      senderId: data['senderId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? '',
      text: data['text'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (data['messageType'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      timestamp: data['timestamp'] != null 
          ? DateTime.tryParse(data['timestamp'].toString())?.toLocal() ?? DateTime.now() 
          : DateTime.now(),
      replyTo: data['replyTo'],
      replyToText: data['replyToText'],
      replyToSender: data['replyToSender'],
      forwardedFrom: data['forwardedFrom'],
      deletedFor: List<String>.from(data['deletedFor'] ?? []),
      deletedForEveryone: data['deletedForEveryone'] ?? false,
      reactions: data['reactions'] is Map 
          ? Map<String, String>.from(data['reactions'].map((key, value) => MapEntry(key.toString(), value.toString()))) 
          : {},
      voiceNoteUrl: data['voiceNoteUrl'],
      voiceNoteDuration: data['voiceNoteDuration'],
      mentions: List<String>.from(data['mentions'] ?? []),
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'messageType': type.name,
      'status': status.name,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'replyTo': replyTo,
      'replyToText': replyToText,
      'replyToSender': replyToSender,
      'forwardedFrom': forwardedFrom,
      'deletedFor': deletedFor,
      'deletedForEveryone': deletedForEveryone,
      'reactions': reactions,
      'voiceNoteUrl': voiceNoteUrl,
      'voiceNoteDuration': voiceNoteDuration,
      'mentions': mentions,
    };
  }

  bool isDeletedFor(String uid) => deletedForEveryone || deletedFor.contains(uid);
  bool get isReply => replyTo != null && replyTo!.isNotEmpty;
  bool get isForwarded => forwardedFrom != null && forwardedFrom!.isNotEmpty;
  bool get isVoiceNote => type == MessageType.voiceNote;
  int get reactionCount => reactions.length;
  bool hasReacted(String uid) => reactions.containsKey(uid);
  String? getReaction(String uid) => reactions[uid];

  String displayText(String currentUid) {
    if (deletedForEveryone) return '🚫 This message was deleted';
    if (deletedFor.contains(currentUid)) return '🚫 You deleted this message';
    if (type == MessageType.voiceNote) return '🎤 Voice note';
    return text;
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? text,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    String? replyTo,
    String? replyToText,
    String? replyToSender,
    String? forwardedFrom,
    List<String>? deletedFor,
    bool? deletedForEveryone,
    Map<String, String>? reactions,
    String? voiceNoteUrl,
    int? voiceNoteDuration,
    List<String>? mentions,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      replyTo: replyTo ?? this.replyTo,
      replyToText: replyToText ?? this.replyToText,
      replyToSender: replyToSender ?? this.replyToSender,
      forwardedFrom: forwardedFrom ?? this.forwardedFrom,
      deletedFor: deletedFor ?? this.deletedFor,
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
      reactions: reactions ?? this.reactions,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      voiceNoteDuration: voiceNoteDuration ?? this.voiceNoteDuration,
      mentions: mentions ?? this.mentions,
    );
  }
}

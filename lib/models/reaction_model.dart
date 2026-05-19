/// Reaction model for emoji reactions on messages
class ReactionModel {
  final String id;
  final String messageId;
  final String userId;
  final String emoji;
  final DateTime timestamp;

  const ReactionModel({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.timestamp,
  });

  factory ReactionModel.fromMap(Map<String, dynamic> map) {
    return ReactionModel(
      id: map['id']?.toString() ?? '',
      messageId: map['messageId'] ?? '',
      userId: map['userId'] ?? '',
      emoji: map['emoji'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.tryParse(map['timestamp'].toString())?.toLocal() ?? DateTime.now() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'messageId': messageId,
      'userId': userId,
      'emoji': emoji,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }
}

/// Group model — maps to Supabase `groups` table
class GroupModel {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final List<String> admins;
  final List<String> members;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String lastMessageSender;
  final DateTime createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.createdBy,
    this.admins = const [],
    this.members = const [],
    this.lastMessage = '',
    this.lastMessageTime,
    this.lastMessageSender = '',
    required this.createdAt,
  });

  factory GroupModel.fromMap(Map<String, dynamic> data) {
    return GroupModel(
      id: data['id']?.toString() ?? '',
      name: data['groupName'] ?? '',
      description: data['groupDescription'] ?? '',
      createdBy: data['createdBy'] ?? '',
      admins: List<String>.from(data['admins'] ?? []),
      members: List<String>.from(data['members'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime'] != null
          ? DateTime.tryParse(data['lastMessageTime'].toString())?.toLocal()
          : null,
      lastMessageSender: data['lastMessageSender'] ?? '',
      createdAt: data['createdAt'] != null 
          ? DateTime.tryParse(data['createdAt'].toString())?.toLocal() ?? DateTime.now() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'groupName': name,
      'groupDescription': description,
      'createdBy': createdBy,
      'admins': admins,
      'members': members,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toUtc().toIso8601String(),
      'lastMessageSender': lastMessageSender,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  bool isAdmin(String uid) => admins.contains(uid);
  bool isMember(String uid) => members.contains(uid);
  bool isCreator(String uid) => createdBy == uid;
  int get memberCount => members.length;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'G';
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    List<String>? admins,
    List<String>? members,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSender,
    DateTime? createdAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      admins: admins ?? this.admins,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

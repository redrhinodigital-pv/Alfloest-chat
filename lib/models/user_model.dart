/// User model — maps to Supabase `users` table
class UserModel {
  final String uid;
  final String displayName;
  final String username;
  final String email;
  final String phone;
  final String photoUrl;
  final String bio;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool darkMode;
  final bool hideOnline;
  final bool hideLastSeen;
  final List<String> blockedUsers;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    this.username = '',
    this.email = '',
    this.phone = '',
    this.photoUrl = '',
    this.bio = '',
    this.isOnline = false,
    this.lastSeen,
    this.darkMode = true,
    this.hideOnline = false,
    this.hideLastSeen = false,
    this.blockedUsers = const [],
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Map (Supabase row or Hive cache)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? map['id'] ?? '',
      displayName: map['displayName'] ?? map['display_name'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'] ?? map['avatar_url'] ?? '',
      bio: map['bio'] ?? '',
      isOnline: map['isOnline'] ?? map['is_online'] ?? false,
      lastSeen: (map['lastSeen'] ?? map['last_seen']) != null
          ? ((map['lastSeen'] ?? map['last_seen']) is int 
              ? DateTime.fromMillisecondsSinceEpoch((map['lastSeen'] ?? map['last_seen'])) 
              : DateTime.tryParse((map['lastSeen'] ?? map['last_seen']).toString())?.toLocal())
          : null,
      darkMode: map['darkMode'] ?? map['dark_mode'] ?? true,
      hideOnline: map['hideOnline'] ?? map['hide_online'] ?? false,
      hideLastSeen: map['hideLastSeen'] ?? map['hide_last_seen'] ?? false,
      blockedUsers: List<String>.from(map['blockedUsers'] ?? map['blocked_users'] ?? []),
      fcmToken: map['fcmToken'] ?? map['fcm_token'],
      createdAt: (map['createdAt'] ?? map['created_at']) != null 
          ? ((map['createdAt'] ?? map['created_at']) is int 
              ? DateTime.fromMillisecondsSinceEpoch((map['createdAt'] ?? map['created_at'])) 
              : DateTime.tryParse((map['createdAt'] ?? map['created_at']).toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      updatedAt: (map['updatedAt'] ?? map['updated_at']) != null 
          ? ((map['updatedAt'] ?? map['updated_at']) is int 
              ? DateTime.fromMillisecondsSinceEpoch((map['updatedAt'] ?? map['updated_at'])) 
              : DateTime.tryParse((map['updatedAt'] ?? map['updated_at']).toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
    );
  }

  /// Convert to Map for Supabase DB
  Map<String, dynamic> toDbMap() {
    return {
      'uid': uid,
      'display_name': displayName,
      'username': username,
      'email': email,
      'phone': phone,
      'avatar_url': photoUrl,
      'bio': bio,
      'is_online': isOnline,
      'last_seen': lastSeen?.toUtc().toIso8601String(),
      'dark_mode': darkMode,
      'hide_online': hideOnline,
      'hide_last_seen': hideLastSeen,
      'blocked_users': blockedUsers,
      'fcm_token': fcmToken,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Convert to Map (for Hive cache)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'username': username,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'bio': bio,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'darkMode': darkMode,
      'hideOnline': hideOnline,
      'hideLastSeen': hideLastSeen,
      'blockedUsers': blockedUsers,
      'fcmToken': fcmToken,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Returns initials for avatar placeholder
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  /// CopyWith for immutable updates
  UserModel copyWith({
    String? uid,
    String? displayName,
    String? username,
    String? email,
    String? phone,
    String? photoUrl,
    String? bio,
    bool? isOnline,
    DateTime? lastSeen,
    bool? darkMode,
    bool? hideOnline,
    bool? hideLastSeen,
    List<String>? blockedUsers,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      darkMode: darkMode ?? this.darkMode,
      hideOnline: hideOnline ?? this.hideOnline,
      hideLastSeen: hideLastSeen ?? this.hideLastSeen,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}

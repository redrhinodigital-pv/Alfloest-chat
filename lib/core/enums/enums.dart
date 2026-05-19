/// Enums used throughout the Alfloest Chat application

/// Type of chat
enum ChatType { oneToOne, group }

/// Message content type
enum MessageType { text, voiceNote, system }

/// Message delivery status
enum MessageStatus { sending, sent, delivered, seen }

/// Notification type
enum NotificationType { message, groupMessage, mention, groupInvite, system }

/// Auth status for state management
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// User online status
enum UserStatus { online, offline, typing }

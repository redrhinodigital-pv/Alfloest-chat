/// App-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Alfloest';
  static const String appFullName = 'Alfloest Chat';
  static const String appVersion = '1.0.0';

  // ── Pagination ──
  static const int messagesPerPage = 30;
  static const int chatsPerPage = 20;
  static const int usersPerPage = 20;

  // ── Limits ──
  static const int maxGroupMembers = 256;
  static const int maxUsernameLength = 30;
  static const int maxBioLength = 150;
  static const int maxMessageLength = 4096;
  static const int maxGroupNameLength = 50;

  // ── Timeouts ──
  static const int typingTimeoutSeconds = 3;
  static const int onlineTimeoutMinutes = 5;

  // ── Audio ──
  static const int maxVoiceNoteDurationSeconds = 120;
  static const String audioFormat = 'aac';

  // ── Hive Boxes ──
  static const String userBox = 'user_box';
  static const String settingsBox = 'settings_box';
  static const String chatCacheBox = 'chat_cache_box';
  static const String messageCacheBox = 'message_cache_box';

  // ── Settings Keys ──
  static const String darkModeKey = 'dark_mode';
  static const String hideOnlineKey = 'hide_online';
  static const String hideLastSeenKey = 'hide_last_seen';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String onboardingCompleteKey = 'onboarding_complete';
}

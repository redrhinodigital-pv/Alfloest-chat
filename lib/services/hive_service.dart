import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/exceptions.dart';

/// Hive local database service — caching and offline support
class HiveService {
  /// Initialize Hive and open all boxes
  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(AppConstants.userBox),
      Hive.openBox(AppConstants.settingsBox),
      Hive.openBox(AppConstants.chatCacheBox),
      Hive.openBox(AppConstants.messageCacheBox),
    ]);
  }

  // ─────────────────────────────────────────────
  // Settings
  // ─────────────────────────────────────────────

  /// Get setting value
  static T? getSetting<T>(String key) {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      return box.get(key) as T?;
    } catch (e) {
      throw CacheException('Failed to get setting: $key', originalError: e);
    }
  }

  /// Set setting value
  static Future<void> setSetting<T>(String key, T value) async {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.put(key, value);
    } catch (e) {
      throw CacheException('Failed to set setting: $key', originalError: e);
    }
  }

  /// Get dark mode preference
  static bool getDarkMode() {
    return getSetting<bool>(AppConstants.darkModeKey) ?? true;
  }

  /// Set dark mode preference
  static Future<void> setDarkMode(bool value) async {
    await setSetting(AppConstants.darkModeKey, value);
  }

  /// Check if onboarding is complete
  static bool isOnboardingComplete() {
    return getSetting<bool>(AppConstants.onboardingCompleteKey) ?? false;
  }

  /// Mark onboarding as complete
  static Future<void> setOnboardingComplete() async {
    await setSetting(AppConstants.onboardingCompleteKey, true);
  }

  /// Get Data Saver preference
  static bool getDataSaver() {
    return getSetting<bool>('data_saver') ?? false;
  }

  /// Set Data Saver preference
  static Future<void> setDataSaver(bool value) async {
    await setSetting('data_saver', value);
  }

  // ─────────────────────────────────────────────
  // User Cache
  // ─────────────────────────────────────────────

  /// Cache user data
  static Future<void> cacheUser(String uid, Map<String, dynamic> data) async {
    try {
      final box = Hive.box(AppConstants.userBox);
      await box.put(uid, data);
    } catch (e) {
      throw CacheException('Failed to cache user', originalError: e);
    }
  }

  /// Get cached user data
  static Map<String, dynamic>? getCachedUser(String uid) {
    try {
      final box = Hive.box(AppConstants.userBox);
      final data = box.get(uid);
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Remove cached user
  static Future<void> removeCachedUser(String uid) async {
    final box = Hive.box(AppConstants.userBox);
    await box.delete(uid);
  }

  // ─────────────────────────────────────────────
  // Chat Cache
  // ─────────────────────────────────────────────

  /// Cache chat list
  static Future<void> cacheChatList(
      String uid, List<Map<String, dynamic>> chats) async {
    try {
      final box = Hive.box(AppConstants.chatCacheBox);
      await box.put(uid, chats);
    } catch (e) {
      throw CacheException('Failed to cache chat list', originalError: e);
    }
  }

  /// Get cached chat list
  static List<Map<String, dynamic>>? getCachedChatList(String uid) {
    try {
      final box = Hive.box(AppConstants.chatCacheBox);
      final data = box.get(uid);
      if (data != null) {
        return List<Map<String, dynamic>>.from(
          (data as List).map((e) => Map<String, dynamic>.from(e)),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // Message Cache
  // ─────────────────────────────────────────────

  /// Cache messages for a chat
  static Future<void> cacheMessages(
      String chatId, List<Map<String, dynamic>> messages) async {
    try {
      final box = Hive.box(AppConstants.messageCacheBox);
      await box.put(chatId, messages);
    } catch (e) {
      throw CacheException('Failed to cache messages', originalError: e);
    }
  }

  /// Get cached messages for a chat
  static List<Map<String, dynamic>>? getCachedMessages(String chatId) {
    try {
      final box = Hive.box(AppConstants.messageCacheBox);
      final data = box.get(chatId);
      if (data != null) {
        return List<Map<String, dynamic>>.from(
          (data as List).map((e) => Map<String, dynamic>.from(e)),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // Cleanup
  // ─────────────────────────────────────────────

  /// Clear all cached data (on logout)
  static Future<void> clearAll() async {
    await Future.wait([
      Hive.box(AppConstants.userBox).clear(),
      Hive.box(AppConstants.chatCacheBox).clear(),
      Hive.box(AppConstants.messageCacheBox).clear(),
    ]);
  }

  /// Clear only settings
  static Future<void> clearSettings() async {
    await Hive.box(AppConstants.settingsBox).clear();
  }
}

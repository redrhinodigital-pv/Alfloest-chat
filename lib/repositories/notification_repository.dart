import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../core/constants/firestore_constants.dart';

/// Notification repository — handles Supabase notification documents
class NotificationRepository {
  final SupabaseService _dbService = SupabaseService();
  final NotificationService _notificationService = NotificationService();

  /// Initialize FCM and get token (keeping FCM for local notifications even if Supabase is backend)
  Future<String?> initFcm(String uid) async {
    final granted = await _notificationService.requestPermission();
    if (!granted) return null;

    final token = await _notificationService.getToken();
    if (token != null) {
      // Save token to Supabase
      await _dbService.updateRow(
        table: FirestoreConstants.usersCollection,
        id: uid,
        data: {'fcmToken': token},
      );
    }
    return token;
  }

  Future<void> subscribeToGroup(String groupId) async {
    await _notificationService.subscribeToTopic('group_$groupId');
  }

  Future<void> unsubscribeFromGroup(String groupId) async {
    await _notificationService.unsubscribeFromTopic('group_$groupId');
  }
}

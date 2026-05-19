/// Notification Service (Mock without Firebase)
class NotificationService {
  Future<void> init() async {}

  Future<bool> requestPermission() async {
    return true; // Mocked
  }

  Future<String?> getToken() async {
    return "mock_supabase_push_token_123";
  }

  Future<void> subscribeToTopic(String topic) async {}

  Future<void> unsubscribeFromTopic(String topic) async {}

  void showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) {}
}

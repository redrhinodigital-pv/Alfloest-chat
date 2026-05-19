import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

/// Notification service provider
final notificationServiceProvider = Provider((ref) => NotificationService());

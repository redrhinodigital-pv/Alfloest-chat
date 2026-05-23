import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../repositories/notification_repository.dart';

/// Notification service provider
final notificationServiceProvider = Provider((ref) => NotificationService());

/// Notification repository provider
final notificationRepositoryProvider = Provider((ref) => NotificationRepository());

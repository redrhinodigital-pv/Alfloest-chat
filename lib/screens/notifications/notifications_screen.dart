import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Notifications screen — placeholder for notification list
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_outlined, size: 40, color: AppColors.textHint),
            ),
            const SizedBox(height: 24),
            Text('No notifications', style: AppTextStyles.heading3.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text("You're all caught up!", style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}

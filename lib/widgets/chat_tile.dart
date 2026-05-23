import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../core/utils/date_formatter.dart';
import '../core/extensions/theme_extensions.dart';
import 'avatar_widget.dart';

/// Chat list tile — displays chat preview on home screen
class ChatTile extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isTyping;
  final bool isPinned;
  final bool isGroup;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ChatTile({
    super.key,
    required this.name,
    this.imageUrl,
    required this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isTyping = false,
    this.isPinned = false,
    this.isGroup = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            AvatarWidget(
              name: name,
              imageUrl: imageUrl,
              size: 52,
              showOnline: !isGroup,
              isOnline: isOnline,
            ),
            const SizedBox(width: 14),

            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      if (lastMessageTime != null)
                        Text(
                          DateFormatter.formatChatListTime(lastMessageTime!),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: unreadCount > 0
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isTyping ? 'typing...' : lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isTyping
                                ? AppColors.primary
                                : context.textSecondary,
                            fontStyle: isTyping ? FontStyle.italic : null,
                          ),
                        ),
                      ),
                      if (isPinned)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(Icons.push_pin,
                              size: 14, color: AppColors.textHint),
                        ),
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

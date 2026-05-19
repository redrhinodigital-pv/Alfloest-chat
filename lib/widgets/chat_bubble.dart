import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../core/enums/enums.dart';
import '../core/utils/date_formatter.dart';

/// Chat bubble widget — supports sent/received, reply, forward, reactions
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isSent;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isReply;
  final String? replyToSender;
  final String? replyToText;
  final bool isForwarded;
  final bool isDeletedForEveryone;
  final Map<String, String> reactions;
  final String? senderName; // for group chats
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onReplyTap;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isSent,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.isReply = false,
    this.replyToSender,
    this.replyToText,
    this.isForwarded = false,
    this.isDeletedForEveryone = false,
    this.reactions = const {},
    this.senderName,
    this.onLongPress,
    this.onDoubleTap,
    this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        onDoubleTap: onDoubleTap,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: EdgeInsets.only(
            left: isSent ? 64 : 12,
            right: isSent ? 12 : 64,
            top: 2,
            bottom: reactions.isNotEmpty ? 12 : 2,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main bubble
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSent ? AppColors.bubbleSent : AppColors.bubbleReceived,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isSent ? 18 : 4),
                    bottomRight: Radius.circular(isSent ? 4 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender name (group chats)
                    if (senderName != null && !isSent)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          senderName!,
                          style: AppTextStyles.chatSender.copyWith(
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),

                    // Forwarded label
                    if (isForwarded)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.reply, size: 14,
                                color: AppColors.textSecondary.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text('Forwarded',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Reply preview
                    if (isReply && replyToText != null)
                      GestureDetector(
                        onTap: onReplyTap,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: AppColors.primaryLight,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (replyToSender != null)
                                Text(
                                  replyToSender!,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              Text(
                                replyToText!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Message text + timestamp row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            isDeletedForEveryone
                                ? '🚫 This message was deleted'
                                : text,
                            style: AppTextStyles.chatMessage.copyWith(
                              color: isDeletedForEveryone
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              fontStyle: isDeletedForEveryone
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Timestamp + status
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormatter.formatMessageTime(timestamp),
                              style: AppTextStyles.chatTimestamp.copyWith(
                                color: isSent
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : AppColors.textHint,
                              ),
                            ),
                            if (isSent) ...[
                              const SizedBox(width: 3),
                              _buildStatusIcon(),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Reactions bar
              if (reactions.isNotEmpty)
                Positioned(
                  bottom: -10,
                  right: isSent ? 8 : null,
                  left: isSent ? null : 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...reactions.values.toSet().map((emoji) {
                          final count = reactions.values.where((e) => e == emoji).length;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              count > 1 ? '$emoji $count' : emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case MessageStatus.sending:
        return const Icon(Icons.access_time, size: 14, color: Colors.white54);
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 14, color: Colors.white54);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 14, color: Colors.white54);
      case MessageStatus.seen:
        return const Icon(Icons.done_all, size: 14, color: AppColors.accent);
    }
  }
}

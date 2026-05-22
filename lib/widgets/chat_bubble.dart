import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../core/enums/enums.dart';
import '../core/utils/date_formatter.dart';
import './voice_note_widget.dart';
import './animated_sticker_widget.dart';

/// Chat bubble widget — supports sent/received, reply, forward, reactions, and media types.
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

  // Media support
  final MessageType type;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final String? voiceNoteUrl;
  final int? voiceNoteDuration;

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
    this.type = MessageType.text,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.voiceNoteUrl,
    this.voiceNoteDuration,
  });

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  void _downloadFile(BuildContext context) async {
    final urlStr = mediaUrl ?? voiceNoteUrl;
    if (urlStr == null || urlStr.isEmpty) return;
    final url = Uri.parse(urlStr);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlStr';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link: $e')),
        );
      }
    }
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glassmorphic background
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.85),
                ),
              ),
            ),
            // Preview Image
            InteractiveViewer(
              maxScale: 4.0,
              child: Image.network(imageUrl),
            ),
            // Close and Download buttons
            Positioned(
              top: 20,
              right: 20,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.download_rounded, color: Colors.white, size: 28),
                    onPressed: () => _downloadFile(context),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                padding: (type == MessageType.sticker || type == MessageType.gif)
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: (type == MessageType.sticker || type == MessageType.gif)
                    ? null // No background for stickers/gifs
                    : BoxDecoration(
                        gradient: isSent ? AppColors.primaryGradient : null,
                        color: isSent ? null : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isSent ? 16 : 4),
                          bottomRight: Radius.circular(isSent ? 4 : 16),
                        ),
                        border: isSent
                            ? null
                            : Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1.0,
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
                            const Icon(Icons.reply, size: 14, color: Colors.white60),
                            const SizedBox(width: 4),
                            Text(
                              'Forwarded',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white60,
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
                            border: const Border(
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

                    // Message Content (Media or Text)
                    if (isDeletedForEveryone)
                      Text(
                        '🚫 This message was deleted',
                        style: AppTextStyles.chatMessage.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      _buildMessageContent(context),

                    const SizedBox(height: 4),

                    // Timestamp + status row below content for cleaner layout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormatter.formatMessageTime(timestamp),
                          style: AppTextStyles.chatTimestamp.copyWith(
                            color: isSent ? Colors.white60 : AppColors.textHint,
                          ),
                        ),
                        if (isSent) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(),
                        ],
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

  Widget _buildMessageContent(BuildContext context) {
    switch (type) {
      case MessageType.image:
        return mediaUrl != null && mediaUrl!.isNotEmpty
            ? GestureDetector(
                onTap: () => _showImagePreview(context, mediaUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: Image.network(
                      mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 150,
                          color: Colors.black12,
                          child: const Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink();

      case MessageType.video:
        return const SizedBox.shrink();

      case MessageType.voiceNote:
        return voiceNoteUrl != null
            ? VoiceMessageBubble(
                url: voiceNoteUrl!,
                isSent: isSent,
                durationSeconds: voiceNoteDuration,
              )
            : const SizedBox.shrink();

      case MessageType.file:
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file, color: AppColors.primaryLight, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName ?? 'Document',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (fileSize != null)
                      Text(
                        _formatFileSize(fileSize!),
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.white70),
                onPressed: () => _downloadFile(context),
              ),
            ],
          ),
        );

      case MessageType.system:
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        );

      case MessageType.sticker:
        return AnimatedStickerWidget(
          url: mediaUrl ?? '',
          size: 150,
        );

      case MessageType.gif:
        return mediaUrl != null && mediaUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
                  child: Image.network(
                    mediaUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.gif_box_outlined, color: Colors.white54, size: 40),
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 150,
                        color: Colors.black12,
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      );
                    },
                  ),
                ),
              )
            : const SizedBox.shrink();

      case MessageType.text:
        return Text(
          text,
          style: AppTextStyles.chatMessage.copyWith(
            color: AppColors.textPrimary,
          ),
        );
    }
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case MessageStatus.sending:
        return const Icon(Icons.access_time, size: 13, color: Colors.white54);
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 13, color: Colors.white54);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 13, color: Colors.white54);
      case MessageStatus.seen:
        return const Icon(Icons.done_all, size: 13, color: AppColors.accent);
    }
  }
}

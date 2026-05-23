import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../core/enums/enums.dart';
import '../core/utils/date_formatter.dart';
import '../core/extensions/theme_extensions.dart';
import '../providers/settings_provider.dart';
import './voice_note_widget.dart';
import './animated_sticker_widget.dart';

/// Chat bubble widget — supports sent/received, reply, forward, reactions, and media types.
/// Re-engineered to support blurred loading, and click-to-load HD previews in Data Saver Mode.
class ChatBubble extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends ConsumerState<ChatBubble> {
  bool _loadFullSize = false;

  /// Reconstruct thumbnail URL dynamically from media URL
  String? get _thumbnailUrl {
    final url = widget.mediaUrl;
    if (url == null) return null;
    if (url.contains('/images/')) {
      return url.replaceAll('/images/', '/thumbnails/');
    }
    return null;
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  void _downloadFile(BuildContext context) async {
    final urlStr = widget.mediaUrl ?? widget.voiceNoteUrl;
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
      alignment: widget.isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: widget.onLongPress,
        onDoubleTap: widget.onDoubleTap,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: EdgeInsets.only(
            left: widget.isSent ? 64 : 12,
            right: widget.isSent ? 12 : 64,
            top: 2,
            bottom: widget.reactions.isNotEmpty ? 12 : 2,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main bubble
              Container(
                padding: (widget.type == MessageType.sticker || widget.type == MessageType.gif)
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: (widget.type == MessageType.sticker || widget.type == MessageType.gif)
                    ? null // No background for stickers/gifs
                    : BoxDecoration(
                        gradient: widget.isSent ? AppColors.primaryGradient : null,
                        color: widget.isSent ? null : context.bubbleReceived,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(widget.isSent ? 16 : 4),
                          bottomRight: Radius.circular(widget.isSent ? 4 : 16),
                        ),
                        border: widget.isSent
                            ? null
                            : Border.all(
                                color: context.isDarkMode
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFE5E7EB),
                                width: 1.0,
                              ),
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender name (group chats)
                    if (widget.senderName != null && !widget.isSent)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          widget.senderName!,
                          style: AppTextStyles.chatSender.copyWith(
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),

                    // Forwarded label
                    if (widget.isForwarded)
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
                    if (widget.isReply && widget.replyToText != null)
                      GestureDetector(
                        onTap: widget.onReplyTap,
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
                              if (widget.replyToSender != null)
                                Text(
                                  widget.replyToSender!,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              Text(
                                widget.replyToText!,
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
                    if (widget.isDeletedForEveryone)
                      Text(
                        '🚫 This message was deleted',
                        style: AppTextStyles.chatMessage.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      _buildMessageContent(context, ref),

                    const SizedBox(height: 4),

                    // Timestamp + status row below content
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormatter.formatMessageTime(widget.timestamp),
                          style: AppTextStyles.chatTimestamp.copyWith(
                            color: widget.isSent ? Colors.white60 : context.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                        if (widget.isSent) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Reactions bar
              if (widget.reactions.isNotEmpty)
                Positioned(
                  bottom: -10,
                  right: widget.isSent ? 8 : null,
                  left: widget.isSent ? null : 8,
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
                        ...widget.reactions.values.toSet().map((emoji) {
                          final count = widget.reactions.values.where((e) => e == emoji).length;
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

  Widget _buildMessageContent(BuildContext context, WidgetRef ref) {
    switch (widget.type) {
      case MessageType.image:
        if (widget.mediaUrl == null || widget.mediaUrl!.isEmpty) return const SizedBox.shrink();
        final dataSaver = ref.watch(dataSaverProvider);
        final shouldDefer = dataSaver && !_loadFullSize;
        final displayUrl = shouldDefer ? (_thumbnailUrl ?? widget.mediaUrl!) : widget.mediaUrl!;

        return GestureDetector(
          onTap: () {
            if (shouldDefer) {
              setState(() => _loadFullSize = true);
            } else {
              _showImagePreview(context, widget.mediaUrl!);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: displayUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
                    ),
                    placeholder: (_, __) => Container(
                      height: 150,
                      color: Colors.black12,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                    // If deferred in Data Saver, blur it cleanly
                    imageBuilder: shouldDefer
                        ? (context, imageProvider) => ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                              child: Image(image: imageProvider, fit: BoxFit.cover),
                            )
                        : null,
                  ),
                  if (shouldDefer)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Load HD (${_formatFileSize(widget.fileSize ?? 0)})',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

      case MessageType.video:
        if (widget.mediaUrl == null || widget.mediaUrl!.isEmpty) return const SizedBox.shrink();
        final dataSaver = ref.watch(dataSaverProvider);
        final shouldDefer = dataSaver && !_loadFullSize;
        final thumbUrl = _thumbnailUrl;

        return GestureDetector(
          onTap: () {
            if (shouldDefer) {
              setState(() => _loadFullSize = true);
            } else {
              _downloadFile(context);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
              color: Colors.black26,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (thumbUrl != null)
                    CachedNetworkImage(
                      imageUrl: thumbUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.video_library, color: Colors.white54, size: 40),
                    )
                  else
                    const Icon(Icons.video_library, color: Colors.white54, size: 40),
                  
                  // Play overlay
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      shouldDefer ? Icons.download_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  
                  if (shouldDefer)
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Load Video (${_formatFileSize(widget.fileSize ?? 0)})',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

      case MessageType.voiceNote:
        return widget.voiceNoteUrl != null
            ? VoiceMessageBubble(
                url: widget.voiceNoteUrl!,
                isSent: widget.isSent,
                durationSeconds: widget.voiceNoteDuration,
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
                      widget.fileName ?? 'Document',
                      style: TextStyle(color: widget.isSent ? Colors.white : context.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.fileSize != null)
                      Text(
                        _formatFileSize(widget.fileSize!),
                        style: TextStyle(color: widget.isSent ? Colors.white70 : context.textSecondary, fontSize: 11),
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
              widget.text,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        );

      case MessageType.sticker:
        return AnimatedStickerWidget(
          url: widget.mediaUrl ?? '',
          size: 150,
        );

      case MessageType.gif:
        return widget.mediaUrl != null && widget.mediaUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
                  child: CachedNetworkImage(
                    imageUrl: widget.mediaUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.gif_box_outlined, color: Colors.white54, size: 40),
                    ),
                    placeholder: (_, __) => Container(
                      height: 150,
                      color: Colors.black12,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink();

      case MessageType.text:
        return Text(
          widget.text,
          style: AppTextStyles.chatMessage.copyWith(
            color: widget.isSent ? Colors.white : context.textPrimary,
          ),
        );
    }
  }

  Widget _buildStatusIcon() {
    switch (widget.status) {
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/message_model.dart';
import '../../core/enums/enums.dart';
import '../../core/utils/date_formatter.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/typing_indicator.dart';
import '../../widgets/emoji_reaction.dart';

/// 1-to-1 Chat screen with realtime messages
class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatScreen({super.key, required this.chatId, required this.otherUserId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;

  // Reply state
  MessageModel? _replyTo;

  @override
  void initState() {
    super.initState();
    // Mark messages as seen when opening chat
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid != null) {
      ref.read(chatRepositoryProvider).markAllAsSeen(widget.chatId, uid);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    // Clear typing status
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid != null) {
      ref.read(chatRepositoryProvider).setTyping(widget.chatId, uid, false);
    }
    super.dispose();
  }

  void _onTextChanged(String text) {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      ref.read(chatRepositoryProvider).setTyping(widget.chatId, uid, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _isTyping = false;
      ref.read(chatRepositoryProvider).setTyping(widget.chatId, uid, false);
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    final userAsync = ref.read(userByIdProvider(uid));
    final senderName = userAsync.value?.displayName ?? '';

    ref.read(chatRepositoryProvider).sendMessage(
      chatId: widget.chatId,
      senderId: uid,
      senderName: senderName,
      text: text,
      replyTo: _replyTo?.id,
      replyToText: _replyTo?.text,
      replyToSender: _replyTo?.senderName,
    );

    _messageController.clear();
    setState(() => _replyTo = null);

    // Auto scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    // Stop typing indicator
    _isTyping = false;
    _typingTimer?.cancel();
    ref.read(chatRepositoryProvider).setTyping(widget.chatId, uid, false);
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).value?.uid ?? '';
    final otherUser = ref.watch(userByIdProvider(widget.otherUserId));
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 30,
        title: otherUser.when(
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Chat'),
          data: (user) => Row(
            children: [
              AvatarWidget(name: user?.displayName ?? '?', imageUrl: user?.photoUrl,
                size: 36, showOnline: true, isOnline: user?.isOnline ?? false),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.displayName ?? 'Unknown',
                      style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                    Text(
                      user?.isOnline == true
                          ? 'online'
                          : user?.lastSeen != null
                              ? DateFormatter.formatLastSeen(user!.lastSeen!)
                              : '',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              switch (val) {
                case 'pin':
                  ref.read(chatRepositoryProvider).togglePin(widget.chatId, uid, true);
                case 'archive':
                  ref.read(chatRepositoryProvider).toggleArchive(widget.chatId, uid, true);
                  Navigator.pop(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'pin', child: Text('Pin Chat')),
              const PopupMenuItem(value: 'archive', child: Text('Archive Chat')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text('No messages yet\nSay hello! 👋',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    if (msg.isDeletedFor(uid)) return const SizedBox.shrink();

                    final isSent = msg.senderId == uid;

                    return ChatBubble(
                      text: msg.displayText(uid),
                      isSent: isSent,
                      timestamp: msg.timestamp,
                      status: msg.status,
                      isReply: msg.isReply,
                      replyToSender: msg.replyToSender,
                      replyToText: msg.replyToText,
                      isForwarded: msg.isForwarded,
                      isDeletedForEveryone: msg.deletedForEveryone,
                      reactions: msg.reactions,
                      onLongPress: () => _showMessageOptions(context, msg, isSent),
                      onDoubleTap: () => _showReactionPicker(context, msg),
                    );
                  },
                );
              },
            ),
          ),

          // Reply preview
          if (_replyTo != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              color: AppColors.surface,
              child: Row(
                children: [
                  Container(width: 3, height: 36, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_replyTo!.senderName, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                        Text(_replyTo!.text, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _replyTo = null)),
                ],
              ),
            ),

          // Message input
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              onChanged: _onTextChanged,
                              maxLines: 4,
                              minLines: 1,
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Message',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 46, height: 46,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context, MessageModel msg, bool isSent) {
    final uid = ref.read(authStateProvider).value?.uid ?? '';
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.reply), title: const Text('Reply'),
              onTap: () { Navigator.pop(context); setState(() => _replyTo = msg); }),
            ListTile(leading: const Icon(Icons.copy), title: const Text('Copy'),
              onTap: () { Clipboard.setData(ClipboardData(text: msg.text)); Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'))); }),
            ListTile(leading: const Icon(Icons.forward), title: const Text('Forward'),
              onTap: () { Navigator.pop(context); /* Forward logic */ }),
            ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Delete for me'),
              onTap: () { ref.read(chatRepositoryProvider).deleteForMe(widget.chatId, msg.id, uid); Navigator.pop(context); }),
            if (isSent)
              ListTile(leading: Icon(Icons.delete_forever, color: AppColors.error),
                title: Text('Delete for everyone', style: TextStyle(color: AppColors.error)),
                onTap: () { ref.read(chatRepositoryProvider).deleteForEveryone(widget.chatId, msg.id); Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context, MessageModel msg) {
    final uid = ref.read(authStateProvider).value?.uid ?? '';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: EmojiReactionWidget(
          onReact: (emoji) {
            ref.read(chatRepositoryProvider).addReaction(widget.chatId, msg.id, uid, emoji);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

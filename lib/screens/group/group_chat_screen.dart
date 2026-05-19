import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/message_model.dart';
import '../../core/enums/enums.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/avatar_widget.dart';

/// Group chat screen
class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupChatScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    final user = ref.read(userByIdProvider(uid)).value;

    ref.read(groupRepositoryProvider).sendGroupMessage(
      groupId: widget.groupId, senderId: uid,
      senderName: user?.displayName ?? '', text: text,
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).value?.uid ?? '';
    final groupAsync = ref.watch(groupProvider(widget.groupId));
    final messagesAsync = ref.watch(groupMessagesProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.when(
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Group'),
          data: (group) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group?.name ?? 'Group', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
              Text('${group?.memberCount ?? 0} members',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(child: Text('No messages yet', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isSent = msg.senderId == uid;
                    return ChatBubble(
                      text: msg.displayText(uid),
                      isSent: isSent,
                      timestamp: msg.timestamp,
                      status: msg.status,
                      senderName: isSent ? null : msg.senderName,
                      reactions: msg.reactions,
                      isDeletedForEveryone: msg.deletedForEveryone,
                    );
                  },
                );
              },
            ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4, minLines: 1,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Message', border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 46, height: 46,
                      decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
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
}

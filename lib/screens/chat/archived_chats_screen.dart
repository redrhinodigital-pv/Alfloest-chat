import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/chat_tile.dart';
import '../../widgets/loading_widget.dart';
import 'chat_screen.dart';

class ArchivedChatsScreen extends ConsumerWidget {
  const ArchivedChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final uid = authState.value?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final chatsAsync = ref.watch(chatsProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Archived Chats'),
      ),
      body: chatsAsync.when(
        loading: () => const LoadingWidget(type: LoadingType.chatList),
        error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: AppColors.error))),
        data: (chats) {
          final archived = chats.where((c) => c.isArchivedBy(uid)).toList();

          if (archived.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.archive_outlined, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('No archived chats', style: AppTextStyles.heading3.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: archived.length,
            itemBuilder: (context, index) {
              final chat = archived[index];
              final otherUid = chat.otherParticipant(uid);
              final userAsync = ref.watch(userByIdProvider(otherUid));

              return userAsync.when(
                loading: () => const SizedBox(height: 72),
                error: (_, __) => const SizedBox.shrink(),
                data: (user) => ChatTile(
                  name: user?.displayName ?? 'Unknown',
                  imageUrl: user?.photoUrl,
                  lastMessage: chat.lastMessage,
                  lastMessageTime: chat.lastMessageTime,
                  unreadCount: chat.getUnreadCount(uid),
                  isOnline: user?.isOnline ?? false,
                  isTyping: chat.isTyping(uid),
                  isPinned: chat.isPinnedBy(uid),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatScreen(chatId: chat.id, otherUserId: otherUid),
                  )),
                  onLongPress: () => _showArchivedOptions(context, ref, chat, uid, otherUid, user?.displayName ?? 'Unknown'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showArchivedOptions(BuildContext context, WidgetRef ref, dynamic chat, String uid, String otherUid, String displayName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                displayName,
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
              ),
            ),
            const Divider(color: AppColors.divider),
            ListTile(
              leading: const Icon(Icons.unarchive_outlined, color: Colors.white),
              title: const Text('Unarchive Chat', style: TextStyle(color: Colors.white)),
              onTap: () {
                ref.read(chatRepositoryProvider).toggleArchive(chat.id, uid, false);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

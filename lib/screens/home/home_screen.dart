import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/chat_tile.dart';
import '../../widgets/loading_widget.dart';
import '../chat/chat_screen.dart';
import '../chat/archived_chats_screen.dart';
import '../group/group_chat_screen.dart';
import '../group/create_group_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../search/search_screen.dart';
import '../notifications/notifications_screen.dart';

/// Home screen — chat list with tabs for chats and groups
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final currentUid = authState.value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Alfloest', style: AppTextStyles.heading2.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              switch (val) {
                case 'profile':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  break;
                case 'archived':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchivedChatsScreen()));
                  break;
                case 'settings':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
              const PopupMenuItem(value: 'archived', child: Text('Archived Chats')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      body: currentUid == null
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _ChatList(uid: currentUid),
                _GroupList(uid: currentUid),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
          }
        },
        child: Icon(_tabController.index == 0 ? Icons.chat_rounded : Icons.group_add_rounded),
      ),
    );
  }
}

/// Chat list tab
class _ChatList extends ConsumerWidget {
  final String uid;
  const _ChatList({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatsProvider(uid));

    return chatsAsync.when(
      loading: () => const LoadingWidget(type: LoadingType.chatList),
      error: (err, _) {
        debugPrint('Chats stream error: $err');
        return const LoadingWidget(type: LoadingType.chatList);
      },
      data: (chats) {
        if (chats.isEmpty) return _buildEmpty(context, 'No chats yet', 'Start a conversation!');

        // Separate pinned and regular chats, exclude archived
        final active = chats.where((c) => !c.isArchivedBy(uid)).toList();
        final pinned = active.where((c) => c.isPinnedBy(uid)).toList();
        final regular = active.where((c) => !c.isPinnedBy(uid)).toList();

        return ListView(
          children: [
            if (pinned.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text('PINNED', style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint, letterSpacing: 1)),
              ),
              ...pinned.map((chat) => _buildChatTile(context, ref, chat, uid)),
              const Divider(),
            ],
            ...regular.map((chat) => _buildChatTile(context, ref, chat, uid)),
          ],
        );
      },
    );
  }

  Widget _buildChatTile(BuildContext context, WidgetRef ref, dynamic chat, String uid) {
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
        onLongPress: () => _showChatOptions(context, ref, chat, uid, otherUid, user?.displayName ?? 'Unknown'),
      ),
    );
  }

  void _showChatOptions(BuildContext context, WidgetRef ref, dynamic chat, String uid, String otherUid, String displayName) {
    final isPinned = chat.isPinnedBy(uid);
    final isArchived = chat.isArchivedBy(uid);
    final isFavorited = chat.isFavoritedBy(uid);

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
              leading: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin, color: Colors.white),
              title: Text(isPinned ? 'Unpin Chat' : 'Pin Chat', style: const TextStyle(color: Colors.white)),
              onTap: () {
                ref.read(chatRepositoryProvider).togglePin(chat.id, uid, !isPinned);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(isArchived ? Icons.unarchive_outlined : Icons.archive_outlined, color: Colors.white),
              title: Text(isArchived ? 'Unarchive Chat' : 'Archive Chat', style: const TextStyle(color: Colors.white)),
              onTap: () {
                ref.read(chatRepositoryProvider).toggleArchive(chat.id, uid, !isArchived);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(isFavorited ? Icons.favorite_border : Icons.favorite, color: isFavorited ? Colors.red : Colors.white),
              title: Text(isFavorited ? 'Remove from Favorites' : 'Add to Favorites', style: const TextStyle(color: Colors.white)),
              onTap: () {
                ref.read(chatRepositoryProvider).toggleFavorite(chat.id, uid, !isFavorited);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cleaning_services_rounded, color: Colors.white),
              title: const Text('Clear Chat History', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final clear = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Clear Chat?', style: TextStyle(color: Colors.white)),
                    content: const Text('This will delete all messages for you. This cannot be undone.', style: TextStyle(color: AppColors.textSecondary)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (clear == true) {
                  await ref.read(chatRepositoryProvider).clearChat(chat.id, uid);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
              title: const Text('Delete Chat', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                final delete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Delete Chat?', style: TextStyle(color: Colors.white)),
                    content: const Text('This will clear and remove this chat from your list.', style: TextStyle(color: AppColors.textSecondary)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (delete == true) {
                  await ref.read(chatRepositoryProvider).deleteChat(chat.id, uid);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.heading3.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
        ],
      ),
    );
  }
}

/// Group list tab
class _GroupList extends ConsumerWidget {
  final String uid;
  const _GroupList({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider(uid));

    return groupsAsync.when(
      loading: () => const LoadingWidget(type: LoadingType.chatList),
      error: (err, _) {
        debugPrint('Groups stream error: $err');
        return const LoadingWidget(type: LoadingType.chatList);
      },
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group_outlined, size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No groups yet', style: AppTextStyles.heading3.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (_, i) {
            final group = groups[i];
            return ChatTile(
              name: group.name,
              lastMessage: group.lastMessage,
              lastMessageTime: group.lastMessageTime,
              isGroup: true,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => GroupChatScreen(groupId: group.id),
              )),
            );
          },
        );
      },
    );
  }
}

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
                case 'settings':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
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
      error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: AppColors.error))),
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
      error: (err, _) => Center(child: Text('Error: $err')),
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

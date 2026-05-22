import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/group_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../../core/utils/date_formatter.dart';
import '../group/group_chat_screen.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? chatId;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.chatId,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _isLoadingGroups = true;
  List<GroupModel> _groupsInCommon = [];

  @override
  void initState() {
    super.initState();
    _loadGroupsInCommon();
  }

  Future<void> _loadGroupsInCommon() async {
    final currentUid = ref.read(authStateProvider).value?.uid;
    if (currentUid == null) return;
    try {
      final groups = await ref.read(groupRepositoryProvider).getGroupsInCommon(currentUid, widget.userId);
      if (mounted) {
        setState(() {
          _groupsInCommon = groups;
          _isLoadingGroups = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingGroups = false;
        });
      }
    }
  }

  void _toggleMute(String chatId, String currentUid, bool isMuted) async {
    try {
      await ref.read(chatRepositoryProvider).toggleMute(chatId, currentUid, !isMuted);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!isMuted ? 'Notifications muted' : 'Notifications unmuted'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update mute status: $e')),
        );
      }
    }
  }

  void _blockUser(UserModel currentUser, UserModel targetUser) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Block ${targetUser.displayName}?', style: const TextStyle(color: Colors.white)),
        content: Text('They will not be able to message you or see your online status.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(userRepositoryProvider).blockUser(currentUser.uid, targetUser.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Blocked ${targetUser.displayName}')),
        );
      }
    }
  }

  void _unblockUser(UserModel currentUser, UserModel targetUser) async {
    await ref.read(userRepositoryProvider).unblockUser(currentUser.uid, targetUser.uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unblocked ${targetUser.displayName}')),
      );
    }
  }

  void _reportUser(UserModel targetUser) async {
    final reasonController = TextEditingController();
    final reported = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Report ${targetUser.displayName}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Why are you reporting this user?', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
                hintStyle: TextStyle(color: AppColors.textHint),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit Report', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (reported == true && reasonController.text.trim().isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for the report. Our moderators will review this profile shortly.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(authStateProvider).value?.uid ?? '';
    final targetUserAsync = ref.watch(userStreamProvider(widget.userId));
    final currentUserAsync = ref.watch(currentUserProvider(currentUid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: targetUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found', style: TextStyle(color: Colors.white)));
          }

          final joinDate = DateFormat('MMMM yyyy').format(user.createdAt);
          final isOnline = user.isOnline;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar & Online Indicator
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Hero(
                        tag: 'avatar_${user.uid}',
                        child: AvatarWidget(
                          name: user.displayName,
                          imageUrl: user.photoUrl,
                          size: 110,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isOnline ? AppColors.online : AppColors.offline,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Name & Username
                Text(
                  user.displayName,
                  style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  user.username.isNotEmpty ? '@${user.username}' : '',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Status
                Text(
                  isOnline
                      ? 'online'
                      : user.lastSeen != null
                          ? DateFormatter.formatLastSeen(user.lastSeen!)
                          : 'offline',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isOnline ? AppColors.online : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // About card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                      const SizedBox(height: 6),
                      Text(
                        user.bio.isNotEmpty ? user.bio : 'No bio shared yet.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      Divider(color: AppColors.divider),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textHint),
                          const SizedBox(width: 8),
                          Text(
                            'Joined $joinDate',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Chat Options (Visible if we have a chatId)
                if (widget.chatId != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text('CHAT SETTINGS', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                    ),
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final chatAsync = ref.watch(chatProvider(widget.chatId!));
                      return chatAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (chat) {
                          if (chat == null) return const SizedBox.shrink();
                          final isPinned = chat.isPinnedBy(currentUid);
                          final isArchived = chat.isArchivedBy(currentUid);
                          final isFavorited = chat.isFavoritedBy(currentUid);

                          final isMuted = chat.isMutedBy(currentUid);

                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider, width: 0.5),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Icon(isFavorited ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorited ? Colors.red : Colors.white),
                                  title: const Text('Favorite Chat', style: TextStyle(color: Colors.white)),
                                  trailing: Switch(
                                    value: isFavorited,
                                    activeThumbColor: AppColors.primary,
                                    onChanged: (val) async {
                                      try {
                                        await ref.read(chatRepositoryProvider).toggleFavorite(widget.chatId!, currentUid, val);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(val ? 'Added to favorites' : 'Removed from favorites'),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to update favorite status: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                                Divider(color: AppColors.divider, height: 1),
                                ListTile(
                                  leading: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: Colors.white),
                                  title: const Text('Pin Chat', style: TextStyle(color: Colors.white)),
                                  trailing: Switch(
                                    value: isPinned,
                                    activeThumbColor: AppColors.primary,
                                    onChanged: (val) async {
                                      try {
                                        await ref.read(chatRepositoryProvider).togglePin(widget.chatId!, currentUid, val);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(val ? 'Chat pinned' : 'Chat unpinned'),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to pin/unpin chat: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                                Divider(color: AppColors.divider, height: 1),
                                ListTile(
                                  leading: Icon(isArchived ? Icons.archive : Icons.archive_outlined, color: Colors.white),
                                  title: const Text('Archive Chat', style: TextStyle(color: Colors.white)),
                                  trailing: Switch(
                                    value: isArchived,
                                    activeThumbColor: AppColors.primary,
                                    onChanged: (val) async {
                                      try {
                                        await ref.read(chatRepositoryProvider).toggleArchive(widget.chatId!, currentUid, val);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(val ? 'Chat archived' : 'Chat unarchived'),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to archive/unarchive chat: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                                Divider(color: AppColors.divider, height: 1),
                                ListTile(
                                  leading: Icon(isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                                  title: const Text('Mute Notifications', style: TextStyle(color: Colors.white)),
                                  trailing: Switch(
                                    value: isMuted,
                                    activeThumbColor: AppColors.primary,
                                    onChanged: (val) => _toggleMute(widget.chatId!, currentUid, isMuted),
                                  ),
                                ),
                                Divider(color: AppColors.divider, height: 1),
                                ListTile(
                                  leading: const Icon(Icons.cleaning_services_rounded, color: Colors.white),
                                  title: const Text('Clear Chat History', style: TextStyle(color: Colors.white)),
                                  onTap: () async {
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
                                      await ref.read(chatRepositoryProvider).clearChat(widget.chatId!, currentUid);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Chat cleared')),
                                        );
                                      }
                                    }
                                  },
                                ),
                                Divider(color: AppColors.divider, height: 1),
                                ListTile(
                                  leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                                  title: const Text('Delete Chat', style: TextStyle(color: AppColors.error)),
                                  onTap: () async {
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
                                      await ref.read(chatRepositoryProvider).deleteChat(widget.chatId!, currentUid);
                                      if (context.mounted) {
                                        Navigator.pop(context); // Close profile screen
                                        Navigator.pop(context); // Close chat screen
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Groups in Common Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('GROUPS IN COMMON', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                  ),
                ),
                _isLoadingGroups
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _groupsInCommon.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                'No shared groups',
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _groupsInCommon.length,
                            itemBuilder: (context, index) {
                              final group = _groupsInCommon[index];
                              return Card(
                                color: AppColors.card,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: AvatarWidget(
                                    name: group.name,
                                    imageUrl: group.groupImage,
                                    size: 40,
                                  ),
                                  title: Text(group.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    group.description.isNotEmpty ? group.description : 'No description',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => GroupChatScreen(groupId: group.id),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                const SizedBox(height: 24),

                // Privacy/Blocking options
                currentUserAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (currentUser) {
                    if (currentUser == null) return const SizedBox.shrink();
                    final isBlocked = currentUser.blockedUsers.contains(user.uid);

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider, width: 0.5),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(isBlocked ? Icons.check_circle_outline : Icons.block,
                                color: isBlocked ? AppColors.success : AppColors.error),
                            title: Text(
                              isBlocked ? 'Unblock User' : 'Block User',
                              style: TextStyle(color: isBlocked ? Colors.white : AppColors.error),
                            ),
                            onTap: () {
                              if (isBlocked) {
                                _unblockUser(currentUser, user);
                              } else {
                                _blockUser(currentUser, user);
                              }
                            },
                          ),
                          Divider(color: AppColors.divider, height: 1),
                          ListTile(
                            leading: const Icon(Icons.report_problem_outlined, color: AppColors.warning),
                            title: const Text('Report User', style: TextStyle(color: Colors.white)),
                            onTap: () => _reportUser(user),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

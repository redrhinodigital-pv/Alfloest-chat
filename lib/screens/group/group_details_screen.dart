import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/gradient_button.dart';
import '../../services/hive_service.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../services/compression_service.dart';
import '../../models/group_model.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleNotifications(bool value) async {
    await HiveService.setSetting<bool>('group_notification_${widget.groupId}', value);
    setState(() {});
  }

  Future<void> _pickGroupImage(GroupModel group) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final originalBytes = await pickedFile.readAsBytes();
      final compressedBytes = await ref.read(compressionServiceProvider).compressImage(
        filePath: pickedFile.path,
        originalBytes: originalBytes,
      );

      final downloadUrl = await ref.read(storageServiceProvider).uploadGroupAvatar(
            filePath: pickedFile.path,
            bytes: compressedBytes,
            groupId: widget.groupId,
          );
      await ref.read(groupRepositoryProvider).updateGroupDetails(widget.groupId, groupImage: downloadUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group image updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update group image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveGroupDetails() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(groupRepositoryProvider).updateGroupDetails(
            widget.groupId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
          );
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group details updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update details: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddMemberSheet(GroupModel group) {
    _searchController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textHint,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Add Members',
                        style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Search by username or email...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (val) {
                          setModalState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _searchController.text.isEmpty
                            ? Center(
                                child: Text(
                                  'Type to search users',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                                ),
                              )
                            : Consumer(
                                builder: (context, ref, _) {
                                  final searchAsync = ref.watch(userSearchProvider(_searchController.text));
                                  return searchAsync.when(
                                    loading: () => const Center(
                                      child: CircularProgressIndicator(color: AppColors.primary),
                                    ),
                                    error: (err, _) => Center(
                                      child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
                                    ),
                                    data: (users) {
                                      final filteredUsers = users
                                          .where((u) => !group.members.contains(u.uid))
                                          .toList();
                                      if (filteredUsers.isEmpty) {
                                        return Center(
                                          child: Text(
                                            'No addable users found',
                                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                                          ),
                                        );
                                      }
                                      return ListView.builder(
                                        controller: scrollController,
                                        itemCount: filteredUsers.length,
                                        itemBuilder: (context, i) {
                                          final user = filteredUsers[i];
                                          return ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: AvatarWidget(
                                              name: user.displayName,
                                              imageUrl: user.photoUrl,
                                              size: 40,
                                            ),
                                            title: Text(
                                              user.displayName,
                                              style: TextStyle(color: AppColors.textPrimary),
                                            ),
                                            subtitle: Text(
                                              '@${user.username}',
                                              style: TextStyle(color: AppColors.textSecondary),
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.add_circle, color: AppColors.primary),
                                              onPressed: () async {
                                                await ref
                                                    .read(groupRepositoryProvider)
                                                    .addMembers(widget.groupId, [user.uid]);
                                                setModalState(() {});
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Added ${user.displayName}')),
                                                  );
                                                }
                                              },
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _leaveGroup(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Leave Group?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to leave this group chat?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(groupRepositoryProvider).removeMember(widget.groupId, uid);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  void _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Group?', style: TextStyle(color: Colors.white)),
        content: const Text('This will delete the group for all members. This cannot be undone.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(supabaseServiceProvider).deleteRow(table: 'groups', id: widget.groupId);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).value?.uid ?? '';
    final groupAsync = ref.watch(groupProvider(widget.groupId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Group Details'),
        actions: [
          groupAsync.when(
            data: (group) {
              if (group == null || !group.isAdmin(uid)) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(_isEditing ? Icons.close : Icons.edit),
                onPressed: () {
                  if (!_isEditing) {
                    _nameController.text = group.name;
                    _descriptionController.text = group.description;
                  }
                  setState(() => _isEditing = !_isEditing);
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (group) {
          if (group == null) {
            return Center(child: Text('Group not found', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)));
          }

          final isGroupAdmin = group.isAdmin(uid);
          final isNotifsEnabled = HiveService.getSetting<bool>('group_notification_${widget.groupId}') ?? true;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // Group Image & Edit option
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.card,
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
                        ),
                        child: ClipOval(
                          child: _isUploadingImage
                              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                              : group.groupImage.isNotEmpty
                                  ? Image.network(group.groupImage, fit: BoxFit.cover)
                                  : Center(
                                      child: Text(
                                        group.initials,
                                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                        ),
                      ),
                      if (isGroupAdmin || _isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _pickGroupImage(group),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Name & Description
                if (_isEditing) ...[
                  TextFormField(
                    controller: _nameController,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter group name' : null,
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                      hintText: 'Enter group name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Group Description',
                      hintText: 'Enter group description',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    text: 'Save Changes',
                    isLoading: _isSaving,
                    onPressed: _saveGroupDetails,
                  ),
                ] else ...[
                  Center(
                    child: Text(
                      group.name,
                      style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      group.description.isNotEmpty ? group.description : 'No description provided',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Settings section
                Text(
                  'Settings',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Card(
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    title: Text('Notifications', style: TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text(
                      isNotifsEnabled ? 'Muted' : 'Unmuted',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    value: isNotifsEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: _toggleNotifications,
                  ),
                ),
                const SizedBox(height: 24),

                // Members section header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Members (${group.members.length})',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    if (isGroupAdmin)
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Member'),
                        onPressed: () => _showAddMemberSheet(group),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Members List
                Card(
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: group.members.length,
                    separatorBuilder: (_, __) => Divider(color: AppColors.divider, height: 1),
                    itemBuilder: (context, idx) {
                      final memberId = group.members[idx];
                      return _GroupMemberTile(
                        memberId: memberId,
                        group: group,
                        currentUserId: uid,
                        isCurrentAdmin: isGroupAdmin,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Group actions
                GradientButton(
                  text: 'Leave Group',
                  onPressed: () => _leaveGroup(uid),
                ),
                if (isGroupAdmin) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: _deleteGroup,
                    child: const Text('Delete Group'),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GroupMemberTile extends ConsumerWidget {
  final String memberId;
  final GroupModel group;
  final String currentUserId;
  final bool isCurrentAdmin;

  const _GroupMemberTile({
    required this.memberId,
    required this.group,
    required this.currentUserId,
    required this.isCurrentAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userStreamProvider(memberId));
    final isUserAdmin = group.isAdmin(memberId);
    final isMe = memberId == currentUserId;

    return userAsync.when(
      loading: () => const ListTile(title: Text('Loading...', style: TextStyle(color: Colors.white))),
      error: (_, __) => const ListTile(title: Text('Error loading member', style: TextStyle(color: Colors.red))),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return ListTile(
          leading: AvatarWidget(
            name: user.displayName,
            imageUrl: user.photoUrl,
            size: 36,
          ),
          title: Row(
            children: [
              Text(
                isMe ? 'You' : user.displayName,
                style: TextStyle(color: AppColors.textPrimary, fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
              ),
              if (isUserAdmin) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text('@${user.username}', style: TextStyle(color: AppColors.textSecondary)),
          trailing: (isCurrentAdmin && !isMe)
              ? PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  onSelected: (val) async {
                    if (val == 'make_admin') {
                      await ref.read(groupRepositoryProvider).makeAdmin(group.id, memberId);
                    } else if (val == 'remove') {
                      await ref.read(groupRepositoryProvider).removeMember(group.id, memberId);
                    }
                  },
                  itemBuilder: (_) => [
                    if (!isUserAdmin)
                      const PopupMenuItem(value: 'make_admin', child: Text('Promote to Admin')),
                    const PopupMenuItem(value: 'remove', child: Text('Remove from Group', style: TextStyle(color: AppColors.error))),
                  ],
                )
              : null,
        );
      },
    );
  }
}

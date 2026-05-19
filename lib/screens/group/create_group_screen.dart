import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/avatar_widget.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';

/// Create group screen
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Set<String> _selectedMembers = {};
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one member')),
      );
      return;
    }

    setState(() => _isCreating = true);
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    await ref.read(groupRepositoryProvider).createGroup(
      name: _nameController.text.trim(),
      createdBy: uid,
      members: _selectedMembers.toList(),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _nameController,
                validator: Validators.validateGroupName,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Group name',
                  prefixIcon: Icon(Icons.group),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search members
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search users to add...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),

            // Selected members chips
            if (_selectedMembers.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _selectedMembers.map((uid) {
                    final user = ref.watch(userByIdProvider(uid)).value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(user?.displayName ?? uid),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _selectedMembers.remove(uid)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 16),

            // Search results
            Expanded(
              child: _searchController.text.isNotEmpty
                  ? _buildSearchResults()
                  : Center(child: Text('Search for users to add',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint))),
            ),

            // Create button
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: GradientButton(
                text: 'Create Group',
                isLoading: _isCreating,
                onPressed: _createGroup,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final searchAsync = ref.watch(userSearchProvider(_searchController.text));
    return searchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (users) {
        if (users.isEmpty) return Center(child: Text('No users found', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)));
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (_, i) {
            final user = users[i];
            final isSelected = _selectedMembers.contains(user.uid);
            return ListTile(
              leading: AvatarWidget(name: user.displayName, imageUrl: user.photoUrl, size: 40),
              title: Text(user.displayName, style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text('@${user.username}', style: TextStyle(color: AppColors.textSecondary)),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : const Icon(Icons.add_circle_outline, color: AppColors.textHint),
              onTap: () => setState(() {
                if (isSelected) _selectedMembers.remove(user.uid);
                else _selectedMembers.add(user.uid);
              }),
            );
          },
        );
      },
    );
  }
}

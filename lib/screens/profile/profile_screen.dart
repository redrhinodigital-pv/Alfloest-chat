import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/gradient_button.dart';
import '../../core/utils/validators.dart';
import '../../services/storage_service.dart';
import '../../services/compression_service.dart';

/// Profile screen — view and edit user profile
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  bool _isEditing = false;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;
      
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid == null) return;
      
      setState(() => _isSaving = true);
      
      final originalBytes = await image.readAsBytes();
      final compressedBytes = await ref.read(compressionServiceProvider).compressImage(
        filePath: image.path,
        originalBytes: originalBytes,
      );

      final storage = ref.read(storageServiceProvider);
      final downloadUrl = await storage.uploadAvatar(
        filePath: image.path,
        bytes: compressedBytes,
        userId: uid,
      );
      
      await ref.read(userRepositoryProvider).updateProfile(uid: uid, photoUrl: downloadUrl);
      setState(() => _isSaving = false);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload avatar: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _removeAvatar() async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    
    setState(() => _isSaving = true);
    try {
      final storage = ref.read(storageServiceProvider);
      await storage.deleteAvatar(userId: uid);
      await ref.read(userRepositoryProvider).updateProfile(uid: uid, photoUrl: '');
      setState(() => _isSaving = false);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove avatar: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.white),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.error),
              title: const Text('Remove Photo', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _removeAvatar();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    setState(() => _isSaving = true);
    await ref.read(userRepositoryProvider).updateProfile(
      uid: uid,
      displayName: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      bio: _bioController.text.trim(),
    );
    setState(() { _isEditing = false; _isSaving = false; });
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).value?.uid ?? '';
    final userAsync = ref.watch(currentUserProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () {
              final user = userAsync.value;
              if (user != null) {
                _nameController.text = user.displayName;
                _usernameController.text = user.username;
                _bioController.text = user.bio;
                setState(() => _isEditing = true);
              }
            }),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar
                GestureDetector(
                  onTap: _isEditing ? _showAvatarOptions : null,
                  child: Stack(
                    children: [
                      AvatarWidget(name: user.displayName, imageUrl: user.photoUrl, size: 100),
                      if (_isEditing)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 30),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_isEditing) ...[
                  TextFormField(
                    controller: _nameController,
                    validator: Validators.validateDisplayName,
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Display Name', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    validator: Validators.validateUsername,
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.alternate_email)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    validator: Validators.validateBio,
                    maxLines: 3,
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Bio', prefixIcon: Icon(Icons.info_outline)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _isEditing = false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: GradientButton(text: 'Save', isLoading: _isSaving, onPressed: _saveProfile)),
                    ],
                  ),
                ] else ...[
                  Text(user.displayName, style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary)),
                  if (user.username.isNotEmpty)
                    Text('@${user.username}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 16),
                  // Info cards
                  _ProfileInfoCard(icon: Icons.info_outline, label: 'Bio', value: user.bio.isNotEmpty ? user.bio : 'No bio yet'),
                  _ProfileInfoCard(icon: Icons.email_outlined, label: 'Email', value: user.email.isNotEmpty ? user.email : 'Not set'),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

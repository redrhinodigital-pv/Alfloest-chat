import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/settings_provider.dart';
import '../auth/login_screen.dart';

/// Settings screen — dark mode, privacy, account actions
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final uid = ref.watch(authStateProvider).value?.uid ?? '';
    final userAsync = ref.watch(currentUserProvider(uid));
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // ── Appearance ──
          _SectionHeader(title: 'Appearance'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_rounded),
            title: const Text('Dark Mode'),
            subtitle: Text(isDark ? 'On' : 'Off'),
            value: isDark,
            onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
          ),
          const Divider(),

          // ── Privacy ──
          _SectionHeader(title: 'Privacy'),
          userAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              return Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.visibility_off_rounded),
                    title: const Text('Hide Online Status'),
                    value: user.hideOnline,
                    onChanged: (val) {
                      ref.read(userRepositoryProvider).updatePrivacy(uid: uid, hideOnline: val);
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.access_time_rounded),
                    title: const Text('Hide Last Seen'),
                    value: user.hideLastSeen,
                    onChanged: (val) {
                      ref.read(userRepositoryProvider).updatePrivacy(uid: uid, hideLastSeen: val);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.block_rounded),
                    title: const Text('Blocked Users'),
                    subtitle: Text('${user.blockedUsers.length} blocked'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to blocked users list
                    },
                  ),
                ],
              );
            },
          ),
          const Divider(),

          // ── Notifications ──
          _SectionHeader(title: 'Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_rounded),
            title: const Text('Push Notifications'),
            value: true,
            onChanged: (_) {
              // Toggle notifications
            },
          ),
          const Divider(),

          // ── Data & Storage ──
          _SectionHeader(title: 'Data & Storage'),
          SwitchListTile(
            secondary: const Icon(Icons.data_saver_on_rounded),
            title: const Text('Data Saver Mode'),
            subtitle: const Text('Aggressive compression, auto-download restricted, audio autoplay disabled'),
            value: ref.watch(dataSaverProvider),
            onChanged: (_) => ref.read(dataSaverProvider.notifier).toggle(),
          ),
          const Divider(),

          // ── Account ──
          _SectionHeader(title: 'Account'),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: AppColors.warning),
            title: Text('Sign Out', style: TextStyle(color: AppColors.warning)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true),
                      child: Text('Sign Out', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authViewModelProvider.notifier).signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_rounded, color: AppColors.error),
            title: Text('Delete Account', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  final textController = TextEditingController();
                  bool isConfirmEnabled = false;

                  return StatefulBuilder(
                    builder: (context, setState) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      final textPrimaryColor = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);

                      return AlertDialog(
                        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
                        title: Text('Delete Account?', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Warning: This action is permanent and will delete all your chats, messages, groups, and notifications.',
                              style: TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            Text('Type DELETE to confirm:', style: TextStyle(color: textPrimaryColor, fontSize: 14)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: textController,
                              autofocus: true,
                              style: TextStyle(color: textPrimaryColor),
                              decoration: InputDecoration(
                                hintText: 'DELETE',
                                border: const OutlineInputBorder(),
                                hintStyle: TextStyle(color: AppColors.textHint.withValues(alpha: 0.5)),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  isConfirmEnabled = val == 'DELETE';
                                });
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: isConfirmEnabled
                                ? () => Navigator.pop(dialogContext, true)
                                : null,
                            child: Text(
                              'DELETE',
                              style: TextStyle(
                                color: isConfirmEnabled ? AppColors.error : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );

              if (confirm == true) {
                if (!context.mounted) return;
                // Show a loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );

                try {
                  await ref.read(authViewModelProvider.notifier).deleteAccount();
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Dismiss loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account permanently deleted.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Dismiss loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete account: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
          ),
          const SizedBox(height: 32),

          // App info
          Center(
            child: Column(
              children: [
                Text('Alfloest Chat', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textHint)),
                Text('v1.0.0', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: AppTextStyles.labelMedium.copyWith(
        color: AppColors.primary, fontWeight: FontWeight.w600)),
    );
  }
}

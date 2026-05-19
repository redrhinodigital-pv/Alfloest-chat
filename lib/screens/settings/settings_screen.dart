import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
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
            onTap: () {
              // Delete account confirmation
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

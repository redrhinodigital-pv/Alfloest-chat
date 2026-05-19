import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

/// Minimal Login screen — purely Google Sign-In with glassmorphism
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // App Icon with glass/glow effect
              Center(
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 50),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text('Alfloest Chat', style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 32)),
              const SizedBox(height: 12),
              Text(
                'A new level of minimal,\nsecure messaging.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary, height: 1.4),
              ),
              const Spacer(),

              // Error banner
              if (authState.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(authState.error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                        ),
                      ],
                    ),
                  ),
                ),

              // Google Auth Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: authState.isLoading ? null : () {
                      ref.read(authViewModelProvider.notifier).signInWithGoogle();
                    },
                    icon: authState.isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                        : const Icon(Icons.g_mobiledata_rounded, size: 36, color: AppColors.surface),
                    label: Text(
                      authState.isLoading ? 'Signing in...' : 'Continue with Google',
                      style: AppTextStyles.button.copyWith(color: AppColors.surface, fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.surface,
                      elevation: 4,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

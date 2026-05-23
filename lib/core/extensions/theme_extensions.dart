import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Context extension to dynamically resolve colors based on the current theme (light/dark mode).
extension ThemeContext on BuildContext {
  /// Checks if dark mode is active.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Dynamic background color.
  Color get background => isDarkMode ? AppColors.background : const Color(0xFFF5F7FF);

  /// Dynamic card/tile background.
  Color get card => isDarkMode ? AppColors.card : const Color(0xFFFFFFFF);

  /// Dynamic surface/sheet background.
  Color get surface => isDarkMode ? AppColors.surface : const Color(0xFFFFFFFF);

  /// Primary text color (high contrast).
  Color get textPrimary => isDarkMode ? AppColors.textPrimary : const Color(0xFF0F172A);

  /// Secondary text color (medium contrast).
  Color get textSecondary => isDarkMode ? AppColors.textSecondary : const Color(0xFF6B7280);

  /// Hint text color (low contrast).
  Color get textHint => isDarkMode ? AppColors.textHint : const Color(0xFF94A3B8);

  /// Divider/border line color.
  Color get divider => isDarkMode ? AppColors.divider : const Color(0xFFE5E7EB);

  /// Outgoing/sent bubble background color.
  Color get bubbleSent => isDarkMode ? AppColors.bubbleSent : AppColors.primary;

  /// Incoming/received bubble background color.
  Color get bubbleReceived => isDarkMode ? AppColors.bubbleReceived : const Color(0xFFFFFFFF);

  /// Chat textfield background color.
  Color get chatInputBackground => isDarkMode ? AppColors.card : const Color(0xFFFFFFFF);
}

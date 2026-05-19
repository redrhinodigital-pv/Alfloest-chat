import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hive_service.dart';

/// Theme mode provider — persists to Hive
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(_loadInitial());

  static ThemeMode _loadInitial() {
    final isDark = HiveService.getDarkMode();
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Toggle between dark and light mode
  void toggle() {
    final isDark = state == ThemeMode.dark;
    state = isDark ? ThemeMode.light : ThemeMode.dark;
    HiveService.setDarkMode(!isDark);
  }

  /// Set specific mode
  void setTheme(ThemeMode mode) {
    state = mode;
    HiveService.setDarkMode(mode == ThemeMode.dark);
  }

  bool get isDark => state == ThemeMode.dark;
}

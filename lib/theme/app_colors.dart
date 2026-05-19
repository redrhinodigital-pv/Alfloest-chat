import 'package:flutter/material.dart';

/// Alfloest Chat color system — dark blue + violet theme
class AppColors {
  AppColors._();

  // ── Primary Palette ──
  static const Color primary = Color(0xFF7C3AED);       // Violet
  static const Color primaryLight = Color(0xFF8B5CF6);   // Light Violet
  static const Color primaryDark = Color(0xFF6D28D9);    // Dark Violet

  // ── Background & Surface ──
  static const Color background = Color(0xFF0F0F23);     // Near Black
  static const Color surface = Color(0xFF16213E);        // Dark Blue Surface
  static const Color card = Color(0xFF1E293B);           // Slate Card
  static const Color navBar = Color(0xFF131A2E);         // Navigation bar

  // ── Text ──
  static const Color textPrimary = Color(0xFFF8FAFC);   // White
  static const Color textSecondary = Color(0xFF94A3B8);  // Muted
  static const Color textHint = Color(0xFF64748B);       // Dim

  // ── Accent / Status ──
  static const Color accent = Color(0xFF3B82F6);         // Blue accent
  static const Color success = Color(0xFF22C55E);        // Green ticks
  static const Color warning = Color(0xFFF59E0B);        // Amber
  static const Color error = Color(0xFFEF4444);          // Red
  static const Color info = Color(0xFF06B6D4);           // Cyan

  // ── Chat Bubbles ──
  static const Color bubbleSent = Color(0xFF7C3AED);     // Violet (self)
  static const Color bubbleReceived = Color(0xFF1E293B); // Slate (other)

  // ── Misc ──
  static const Color divider = Color(0xFF1E293B);
  static const Color shimmerBase = Color(0xFF1E293B);
  static const Color shimmerHighlight = Color(0xFF334155);
  static const Color online = Color(0xFF22C55E);
  static const Color offline = Color(0xFF64748B);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Light Theme Colors (for future use) ──
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
}

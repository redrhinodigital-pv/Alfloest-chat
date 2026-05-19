import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App typography — uses Inter font family via Google Fonts
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base => GoogleFonts.inter();

  // ── Headings ──
  static TextStyle heading1 = _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle heading2 = _base.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  static TextStyle heading3 = _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  // ── Body ──
  static TextStyle bodyLarge = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodyMedium = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodySmall = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // ── Labels ──
  static TextStyle labelLarge = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // ── Chat Specific ──
  static TextStyle chatMessage = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static TextStyle chatTimestamp = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  static TextStyle chatSender = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  // ── Buttons ──
  static TextStyle button = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static TextStyle buttonSmall = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
}

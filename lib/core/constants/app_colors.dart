import 'package:flutter/material.dart';

class AppColors {
  // -------------------------
  // Brand Colors
  // -------------------------
  static const Color primary = Color(0xFF28A745);      // Main brand green
  static const Color secondary = Color(0xFF171A1F);    // Dark accent / text background
  static const Color accent = Color(0xFF9095A1);       // Secondary accent / gradients

  // -------------------------
  // Backgrounds
  // -------------------------
  static const Color background = Color(0xFFFAFAFA);    // Scaffold, pages
  static const Color surface = Color(0xFFF5F6FA);       // Cards, sections

  // -------------------------
  // Text Colors
  // -------------------------
  static const Color textPrimary = Color(0xFF000000);  // Main text
  static const Color textSecondary = Color(0xFF9095A1);// Secondary text / subtitles
  static const Color textHint = Color(0xFF6C757D);     // Placeholder / hints
  static const Color textWhite = Colors.white;

  // -------------------------
  // Feedback / Status
  // -------------------------
  static const Color error = Color(0xFFDC3545);        // Error messages
  static const Color success = Color(0xFF28A745);      // Success / confirmations
  static const Color warning = Color(0xFFFFC107);      // Optional: warning

  // -------------------------
  // Gradients
  // -------------------------
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [accent, secondary],
  );

  // -------------------------
  // Borders / Dividers
  // -------------------------
  static const Color border = Color(0xFFE0E0E0);
}

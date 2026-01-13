import 'package:collab_bot/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class Helpers {
  // -------------------------
  // Show a SnackBar
  // -------------------------
  static void showSnackBar(BuildContext context, String message,
      {Color backgroundColor = AppColors.primary}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // -------------------------
  // Format DateTime to readable string
  // -------------------------
  static String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2,'0')}-${date.month.toString().padLeft(2,'0')}-${date.year}";
  }

  // -------------------------
  // Capitalize first letter
  // -------------------------
  static String capitalize(String text) {
    if (text.isEmpty) return "";
    return text[0].toUpperCase() + text.substring(1);
  }

  // -------------------------
  // Convert list of strings to comma separated string
  // -------------------------
  static String listToString(List<String> list) {
    return list.join(", ");
  }
}

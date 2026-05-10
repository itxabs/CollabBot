import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class UserRoleIcon extends StatelessWidget {
  final String? role;
  final double size;

  const UserRoleIcon({super.key, required this.role, this.size = 14});

  static const String junior = 'junior';
  static const String senior = 'senior';
  static const String alumni = 'alumni';

  @override
  Widget build(BuildContext context) {
    final normalizedRole = role?.trim().toLowerCase();

    if (normalizedRole == null || normalizedRole.isEmpty) {
      return const SizedBox.shrink();
    }

    final iconData = _iconForRole(normalizedRole);
    final iconColor = _colorForRole(normalizedRole);

    return Icon(iconData, size: size, color: iconColor);
  }

  IconData _iconForRole(String normalizedRole) {
    switch (normalizedRole) {
      case junior:
        return Icons.circle;
      case senior:
        return Icons.star;
      case alumni:
        return Icons.school;
      default:
        return Icons.person;
    }
  }

  Color _colorForRole(String normalizedRole) {
    switch (normalizedRole) {
      case junior:
        return Colors.blue.shade500;
      case senior:
        return AppColors.primary;
      case alumni:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}

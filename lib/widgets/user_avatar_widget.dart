import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class UserAvatarWidget extends StatelessWidget {
  final String? name;
  final String? avatarUrl;
  final double radius;

  const UserAvatarWidget({
    super.key,
    required this.name,
    required this.avatarUrl,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = avatarUrl?.trim();
    if (normalizedUrl == null || normalizedUrl.isEmpty) {
      return _buildInitialsAvatar();
    }

    final size = radius * 2;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      child: ClipOval(
        child: Image.network(
          normalizedUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }
            return SizedBox(
              width: size,
              height: size,
              child: Center(
                child: SizedBox(
                  width: radius,
                  height: radius,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _buildInitialsContent(),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      child: _buildInitialsContent(),
    );
  }

  Widget _buildInitialsContent() {
    return Text(
      _initials(name),
      style: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String _initials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return 'U';
    }
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

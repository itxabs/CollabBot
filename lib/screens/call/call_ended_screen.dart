import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class CallEndedScreen extends StatelessWidget {
  final String callerName;
  final String callerRole;
  final String callDuration;
  final String statusLabel;
  final String? avatarUrl;
  final String? chatId;
  final String? otherUserId;

  const CallEndedScreen({
    super.key,
    this.callerName = 'Participant',
    this.callerRole = '',
    this.callDuration = '00:00',
    this.statusLabel = 'Call ended',
    this.avatarUrl,
    this.chatId,
    this.otherUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF101317),
                AppColors.secondary,
              ],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1B1F26),
                  ),
                  child: const Icon(
                    Icons.mic_off,
                    color: AppColors.accent,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              CircleAvatar(
                radius: 68,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 64,
                        color: AppColors.textWhite,
                      )
                    : null,
              ),
              const SizedBox(height: 24),
              Text(
                callerName,
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.textWhite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$statusLabel • $callDuration',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 40),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

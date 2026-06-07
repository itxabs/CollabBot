import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/call_helper.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String callerRole;
  final String callLabel;
  final String? avatarUrl;
  final String callType;

  const IncomingCallScreen({
    super.key,
    this.callerName = 'Caller',
    this.callerRole = '',
    this.callLabel = 'Incoming Call',
    this.avatarUrl,
    this.callType = 'audio',
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  Timer? _statusTimer;
  bool _watchStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_watchStarted) return;
    _watchStarted = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final callId = args?['callId']?.toString();
    if (callId == null || callId.isEmpty) return;

    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final call = await Supabase.instance.client
            .from('calls')
            .select('status')
            .eq('id', callId)
            .maybeSingle();
        final status = (call as Map<String, dynamic>?)?['status'] as String?;
        if (!mounted) return;
        if (status == null ||
            status == 'ended' ||
            status == 'rejected' ||
            status == 'missed') {
          _statusTimer?.cancel();
          Navigator.of(context).pop();
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.secondary, Color(0xFF12151A)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.callLabel,
                      style: AppTextStyles.subtitle1.copyWith(
                        color: AppColors.textWhite,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withOpacity(0.95),
                            AppColors.primary.withOpacity(0.35),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 30,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: CircleAvatar(
                          radius: 78,
                          backgroundColor: AppColors.secondary,
                          backgroundImage: widget.avatarUrl != null
                              ? NetworkImage(widget.avatarUrl!)
                              : null,
                          child: widget.avatarUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 72,
                                  color: AppColors.textWhite,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    widget.callerName,
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.textWhite,
                      fontSize: 32,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.callerRole.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.callerRole,
                      style: AppTextStyles.subtitle2.copyWith(
                        color: AppColors.accent,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.callType == 'video' ? 'Video Call' : 'Voice Call',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Incoming call',
                    style: AppTextStyles.subtitle1.copyWith(
                      color: AppColors.textWhite.withOpacity(0.75),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionButton(
                        icon: Icons.call_end,
                        label: 'Decline',
                        backgroundColor: AppColors.error,
                        onTap: () {
                          _statusTimer?.cancel();
                          final args =
                              ModalRoute.of(context)?.settings.arguments
                                  as Map<String, dynamic>?;
                          final callId = args != null
                              ? args['callId']?.toString()
                              : null;
                          if (callId != null) {
                            CallHelper.declineCall(callId);
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                      _ActionButton(
                        icon: Icons.call,
                        label: 'Accept',
                        backgroundColor: AppColors.primary,
                        onTap: () {
                          _statusTimer?.cancel();
                          final args =
                              ModalRoute.of(context)?.settings.arguments
                                  as Map<String, dynamic>?;
                          final callId = args != null
                              ? args['callId']?.toString()
                              : null;
                          final chatId = args != null
                              ? args['chatId']?.toString()
                              : null;
                          final callerId = args != null
                              ? args['callerId']?.toString()
                              : null;
                          final callType = args != null
                              ? args['callType'] as String?
                              : null;
                          if (chatId != null && callId != null) {
                            CallHelper.answerCall(
                              context,
                              chatId,
                              callId,
                              callType,
                              callerName: widget.callerName,
                              avatarUrl: widget.avatarUrl,
                              otherUserId: callerId,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        shadowColor: backgroundColor.withOpacity(0.35),
      ),
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: AppColors.textWhite),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.button),
        ],
      ),
    );
  }
}

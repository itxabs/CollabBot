import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/routes.dart';
import '../../core/services/call_helper.dart';

class ActiveCallScreen extends StatefulWidget {
  final String appId;
  final String token;
  final String channel;
  final int uid;
  final bool enableVideo;
  final String callerName;
  final String callerRole;
  final String? avatarUrl;
  final String? chatId;
  final String? otherUserId;
  final String? callId;

  const ActiveCallScreen({
    super.key,
    required this.appId,
    required this.token,
    required this.channel,
    this.uid = 0,
    this.enableVideo = false,
    this.callerName = 'Participant',
    this.callerRole = '',
    this.avatarUrl,
    this.chatId,
    this.otherUserId,
    this.callId,
  });

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  late final RtcEngine _engine;
  int? _remoteUid;
  bool _joined = false;
  bool _engineReady = false;
  bool _endingLocally = false;
  bool _leftChannel = false;
  Timer? _timer;
  Timer? _statusTimer;
  Duration _elapsed = Duration.zero;
  bool _muted = false;
  bool _speakerOn = false; // default to earpiece for audio calls, will be overridden to true for video calls
  bool _videoOn = false;

  @override
  void initState() {
    super.initState();
    _videoOn = widget.enableVideo;
    // Set speaker to ON for video calls by default, OFF for audio calls
    if (widget.enableVideo) {
      _speakerOn = true;
    }
    _initAgora();
    _startCallStatusWatcher();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusTimer?.cancel();
    _leaveChannel();
    super.dispose();
  }

  Future<void> _initAgora() async {
    // Request permissions
    final micStatus = await Permission.microphone.request();
    final cameraStatus = widget.enableVideo
        ? await Permission.camera.request()
        : PermissionStatus.granted;
    if (!micStatus.isGranted || !cameraStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone/camera permission is required for calls'),
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    try {
      _engine = createAgoraRtcEngine();
      await _engine.initialize(
        RtcEngineContext(
          appId: widget.appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      _engineReady = true;

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            if (!mounted) return;
            setState(() {
              _joined = true;
            });
            unawaited(
              _engine.setEnableSpeakerphone(_speakerOn).catchError((_) {}),
            );
            _maybeStartTimer();
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            if (!mounted) return;
            setState(() {
              _remoteUid = remoteUid;
            });
            _maybeStartTimer();
          },
          onUserOffline: (connection, remoteUid, reason) {
            if (!mounted) return;
            setState(() {
              if (_remoteUid == remoteUid) _remoteUid = null;
            });
          },
        ),
      );

      await _engine.enableAudio();

      if (widget.enableVideo) {
        await _engine.enableVideo();
        await _engine.startPreview();
      }

      await _engine.joinChannel(
        token: widget.token,
        channelId: widget.channel,
        uid: widget.uid,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          publishCameraTrack: widget.enableVideo,
          autoSubscribeVideo: widget.enableVideo,
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted || _joined) return;
        setState(() {
          _joined = true;
        });
        _maybeStartTimer();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Agora join failed: $e')));
        Navigator.of(context).pop();
      }
    }
  }

  void _startTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed = _elapsed + const Duration(seconds: 1));
    });
  }

  /// Start the elapsed timer only when both local client has joined and a
  /// remote participant uid has been observed.
  void _maybeStartTimer() {
    if (_timer != null) return;
    if (!_joined) return;
    if (_remoteUid == null) return;
    _startTimer();
  }

  Future<void> _leaveChannel() async {
    if (!_engineReady || _leftChannel) return;
    _leftChannel = true;
    try {
      await _engine.leaveChannel();
      await _engine.release();
    } catch (_) {}
  }

  void _startCallStatusWatcher() {
    final callId = widget.callId;
    if (callId == null || callId.isEmpty) return;

    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || _endingLocally) return;
      try {
        final call = await Supabase.instance.client
            .from('calls')
            .select('status')
            .eq('id', callId)
            .maybeSingle();
        final status = (call as Map<String, dynamic>?)?['status'] as String?;
        if (status == 'ended' || status == 'rejected' || status == 'missed') {
          _statusTimer?.cancel();
          await _leaveChannel();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(
              AppRoutes.callEnded,
              arguments: {
                'callerName': widget.callerName,
                'callerRole': widget.callerRole,
                'avatarUrl': widget.avatarUrl,
                'chatId': widget.chatId,
                'otherUserId': widget.otherUserId,
                'callDuration': _formatDuration(_elapsed),
                'statusLabel': status == 'ended' ? 'Call ended' : status == 'rejected' ? 'Call rejected' : 'Missed call',
              },
            );
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _endCallForEveryone() async {
    _endingLocally = true;
    _statusTimer?.cancel();
    final callId = widget.callId;
    if (callId != null && callId.isNotEmpty) {
      await CallHelper.endCall(callId);
    }
    await _leaveChannel();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.callEnded,
        arguments: {
          'callerName': widget.callerName,
          'callerRole': widget.callerRole,
          'avatarUrl': widget.avatarUrl,
          'chatId': widget.chatId,
          'otherUserId': widget.otherUserId,
          'callDuration': _formatDuration(_elapsed),
          'statusLabel': 'Call ended',
        },
      );
    }
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: widget.enableVideo ? _buildVideoScreen() : _buildAudioScreen(),
      ),
    );
  }

  Widget _buildAudioScreen() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                'VOICE CALL',
                style: AppTextStyles.subtitle2.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2ECC71),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_elapsed),
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textWhite,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(child: _buildAudioLayout()),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 16,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CircleIconButton(
                      icon: _muted ? Icons.mic_off : Icons.mic,
                      label: 'Mute',
                      backgroundColor:
                          _muted ? AppColors.primary : AppColors.surface,
                      iconColor:
                          _muted ? AppColors.textWhite : AppColors.textPrimary,
                      onTap: () async {
                        setState(() => _muted = !_muted);
                        if (_engineReady) {
                          try {
                            await _engine.enableLocalAudio(!_muted);
                            await _engine.muteLocalAudioStream(_muted);
                          } catch (_) {}
                        }
                      },
                    ),
                    _CircleIconButton(
                      icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
                      label: 'Speaker',
                      backgroundColor:
                          _speakerOn ? AppColors.primary : AppColors.surface,
                      iconColor:
                          _speakerOn ? AppColors.textWhite : AppColors.textPrimary,
                      onTap: () async {
                        setState(() => _speakerOn = !_speakerOn);
                        if (_engineReady) {
                          try {
                            await _engine.setEnableSpeakerphone(_speakerOn);
                          } catch (_) {}
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _endCallForEveryone,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.28),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.call_end,
                    color: AppColors.textWhite,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoScreen() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _engineReady
            ? (_remoteUid != null
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection: RtcConnection(channelId: widget.channel),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.secondary.withOpacity(0.95),
                          AppColors.secondary.withOpacity(0.65),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
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
                                  color: AppColors.primary.withOpacity(0.22),
                                  blurRadius: 28,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
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
                          const SizedBox(height: 18),
                          Text(
                            widget.callerName,
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.textWhite,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Waiting for participant...',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textWhite.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
            : const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
        Positioned(
          top: 24,
          left: 24,
          right: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.callerName,
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2ECC71),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(_elapsed),
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textWhite,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: _flipCamera,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.72),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flip_camera_android,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 24,
          bottom: 182,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 120,
              height: 160,
              color: AppColors.surface.withOpacity(0.12),
              child: _engineReady
                  ? AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.40),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CircleIconButton(
                  icon: _muted ? Icons.mic_off : Icons.mic,
                  label: 'Mute',
                  backgroundColor:
                      _muted ? AppColors.primary : AppColors.surface,
                  iconColor:
                      _muted ? AppColors.textWhite : AppColors.textPrimary,
                  onTap: () async {
                    setState(() => _muted = !_muted);
                    if (_engineReady) {
                      try {
                        await _engine.enableLocalAudio(!_muted);
                        await _engine.muteLocalAudioStream(_muted);
                      } catch (_) {}
                    }
                  },
                ),
                _CircleIconButton(
                  icon: _videoOn ? Icons.videocam : Icons.videocam_off,
                  label: 'Video',
                  backgroundColor:
                      _videoOn ? AppColors.surface : AppColors.primary,
                  iconColor:
                      _videoOn ? AppColors.textPrimary : AppColors.textWhite,
                  onTap: () async {
                    setState(() => _videoOn = !_videoOn);
                    if (_engineReady) {
                      try {
                        await _engine.enableLocalVideo(_videoOn);
                        await _engine.muteLocalVideoStream(!_videoOn);
                        if (_videoOn) {
                          await _engine.startPreview();
                        } else {
                          await _engine.stopPreview();
                        }
                      } catch (_) {}
                    }
                  },
                ),
                GestureDetector(
                  onTap: _endCallForEveryone,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withOpacity(0.28),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: AppColors.textWhite,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _flipCamera() async {
    if (!_engineReady) return;
    try {
      await _engine.switchCamera();
    } catch (_) {}
  }

  Widget _buildAudioLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
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
                color: AppColors.primary.withOpacity(0.22),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 78,
            backgroundColor: AppColors.secondary,
            backgroundImage: widget.avatarUrl != null
                ? NetworkImage(widget.avatarUrl!)
                : null,
            child: widget.avatarUrl == null
                ? const Icon(Icons.person, size: 72, color: AppColors.textWhite)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.callerName,
          style: AppTextStyles.heading2.copyWith(color: AppColors.textWhite),
        ),
        if (widget.callerRole.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.callerRole,
            style: AppTextStyles.subtitle1.copyWith(color: AppColors.accent),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            'End-to-end encrypted',
            style: AppTextStyles.subtitle1.copyWith(color: AppColors.accent),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Call is active.',
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textWhite.withOpacity(0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoLayout() {
    if (!_engineReady) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: _remoteUid != null
              ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _engine,
                    canvas: VideoCanvas(uid: _remoteUid),
                    connection: RtcConnection(channelId: widget.channel),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.secondary.withOpacity(0.95),
                        AppColors.secondary.withOpacity(0.65),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
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
                                color: AppColors.primary.withOpacity(0.22),
                                blurRadius: 28,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
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
                        const SizedBox(height: 18),
                        Text(
                          widget.callerName,
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.textWhite,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Waiting for participant...',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textWhite.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        Positioned(
          right: 24,
          top: 24,
          child: GestureDetector(
            onTap: _flipCamera,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.72),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.22)),
              ),
              child: const Icon(
                Icons.flip_camera_android,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        Positioned(
          right: 24,
          top: 90,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2ECC71),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_elapsed),
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 24,
          bottom: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 120,
              height: 160,
              color: AppColors.surface.withOpacity(0.12),
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleIconButton({
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textWhite.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

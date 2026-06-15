import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../core/services/call_helper.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

import '../../data/models/message_model.dart';
import '../../core/services/chat_presence_service.dart';
import '../../view_model/chat_view_model.dart';
import '../../widgets/user_role_icon.dart';
import '../../widgets/report_bottom_sheet.dart';

class ChatScreen extends StatelessWidget {
  final String chatId;
  final String otherName;
  final String? otherUserId;
  final String? otherUserRole;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherName,
    this.otherUserId,
    this.otherUserRole,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(
        chatId: chatId,
        otherUserName: otherName,
        otherUserId: otherUserId,
      ),
      child: _ChatScreenContent(
        chatId: chatId,
        otherUserName: otherName,
        otherUserRole: otherUserRole,
        otherUserId: otherUserId,
      ),
    );
  }
}

class _ChatScreenContent extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String? otherUserRole;
  final String? otherUserId;
  const _ChatScreenContent({
    required this.chatId,
    required this.otherUserName,
    this.otherUserRole,
    this.otherUserId,
  });

  @override
  State<_ChatScreenContent> createState() => _ChatScreenContentState();
}

class _ChatScreenContentState extends State<_ChatScreenContent> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  Future<Position?>? _currentPositionFuture;
  List<PlatformFile> _selectedFiles = [];
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    ChatPresenceService.instance.setActiveChat(widget.chatId);
    _currentPositionFuture = _resolveCurrentPosition();
  }

  @override
  void dispose() {
    ChatPresenceService.instance.clearActiveChat(widget.chatId);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  Future<Position?> _resolveCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result == null) return;
    setState(() {
      _selectedFiles = result.files.where((file) => file.path != null).toList();
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result == null) return;
    setState(() {
      _selectedFiles.addAll(
        result.files.where((file) => file.path != null).toList(),
      );
    });
  }

  Future<void> _shareLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services.')),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied. Please enable them in settings.',
            ),
          ),
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );
      if (!mounted) return;
      final vm = context.read<ChatViewModel>();
      await vm.sendMessage(
        'Shared location',
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location shared successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share location: $e')),
      );
    }
  }

  void _insertEmoji() {
    setState(() {
      _showEmoji = !_showEmoji;
    });
    if (_showEmoji) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  Widget _buildAttachmentPreview(PlatformFile file) {
    final isImage =
        file.extension != null &&
        [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'bmp',
          'heic',
        ].contains(file.extension!.toLowerCase());
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.grey.shade200,
                child: isImage && file.path != null
                    ? Image.file(File(file.path!), fit: BoxFit.cover)
                    : Center(
                        child: Icon(
                          Icons.insert_drive_file,
                          color: Colors.grey.shade600,
                          size: 28,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            file.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(BuildContext context, LocalMessage message, attachment) {
    final vm = context.read<ChatViewModel>();
    final downloaded = attachment.isDownloaded && attachment.localPath != null;
    final stateLabel = downloaded
        ? 'Downloaded'
        : attachment.downloadState == 'downloading'
        ? 'Downloading'
        : attachment.downloadState == 'failed'
        ? 'Retry'
        : 'Tap to download';

    return GestureDetector(
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final path = await vm.openAttachment(message, attachment);
        if (path == null) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Failed to open attachment')),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (attachment.isImage)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade200,
                  image: attachment.localPath != null
                      ? DecorationImage(
                          image: FileImage(File(attachment.localPath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: attachment.localPath == null
                    ? const Icon(Icons.image, size: 32, color: Colors.grey)
                    : null,
              )
            else
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade200,
                ),
                child: const Icon(
                  Icons.insert_drive_file,
                  size: 32,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stateLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: downloaded
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              downloaded ? Icons.check_circle : Icons.cloud_download,
              color: downloaded ? Colors.green : Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationMessageCard(LocalMessage message, bool isMine) {
    final LatLng locationPoint = LatLng(message.latitude!, message.longitude!);
    return GestureDetector(
      onTap: () async {
        final currentPosition = await _currentPositionFuture ?? await _resolveCurrentPosition();
        final userLatLng = currentPosition != null
            ? LatLng(currentPosition.latitude, currentPosition.longitude)
            : null;
        if (!mounted) return;
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, secondaryAnimation) => FadeTransition(
              opacity: animation,
              child: LocationMapScreen(
                destination: locationPoint,
                userLocation: userLatLng,
                otherName: isMine ? 'Shared by You' : widget.otherUserName,
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: isMine ? Colors.blue.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isMine ? Colors.blue.shade300 : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 150,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: locationPoint,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.collab_bot',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: locationPoint,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.redAccent,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content.isNotEmpty ? message.content : 'Shared location',
                    style: TextStyle(
                      color: isMine ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FutureBuilder<Position?>(
                    future: _currentPositionFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done || snapshot.data == null) {
                        return Text(
                          'Tap to view full map',
                          style: TextStyle(
                            color: isMine ? Colors.white70 : Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        );
                      }
                      final distanceMeters = Geolocator.distanceBetween(
                        snapshot.data!.latitude,
                        snapshot.data!.longitude,
                        message.latitude!,
                        message.longitude!,
                      );
                      final distanceKm = distanceMeters / 1000;
                      return Text(
                        '📍 ${distanceKm.toStringAsFixed(1)} km away',
                        style: TextStyle(
                          color: isMine ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRetryDialog(BuildContext context, ChatViewModel vm, LocalMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Failed'),
        content: const Text(
          'This message failed to send. Tap "Retry" to send it again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              vm.retryFailedMessage(message);
              Navigator.pop(context);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showAiBottomMenu(BuildContext context, ChatViewModel vm, LocalMessage message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: Colors.blue),
                title: const Text('Get answer from AI'),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  if (message.content.trim().isEmpty) return;
                  final suggestion = await vm.generateAiResponse(message.content);
                  if (suggestion != null && suggestion.isNotEmpty) {
                    setState(() {
                      _controller.text = suggestion;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    if (!vm.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToBottom();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0] : 'U',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.otherUserName,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.h3.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if ((widget.otherUserRole ?? '').trim().isNotEmpty) ...[
                        const SizedBox(width: 4),
                        UserRoleIcon(role: widget.otherUserRole),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Audio call',
            icon: Icon(Icons.call_outlined, color: AppColors.textPrimary, size: 22),
            onPressed: () => CallHelper.startCall(
                context,
                widget.chatId,
                widget.otherUserName,
                widget.otherUserRole,
                widget.otherUserId,
                false),
          ),
          IconButton(
            tooltip: 'Video call',
            icon: Icon(Icons.videocam_outlined, color: AppColors.textPrimary, size: 22),
            onPressed: () => CallHelper.startCall(
                context,
                widget.chatId,
                widget.otherUserName,
                widget.otherUserRole,
                widget.otherUserId,
                true),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'report') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ReportBottomSheet(
                    targetUserId: widget.otherUserId,
                    contentType: 'user',
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: AppColors.error, size: 20),
                    SizedBox(width: 12),
                    Text('Report User', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: PopScope(
        canPop: !_showEmoji,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_showEmoji) {
            setState(() {
              _showEmoji = false;
            });
          }
        },
        child: SafeArea(
          top: false,
          bottom: true,
          child: Column(
            children: [
              if (vm.isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: vm.messages.length,
                  itemBuilder: (context, index) {
                    final LocalMessage message = vm.messages[index];
                    final currentUser =
                        Supabase.instance.client.auth.currentUser;
                    final isMine =
                        currentUser != null &&
                        message.senderId == currentUser.id;
                    final isFailed = isMine && message.status == 'failed';

                    return Padding(
                      padding: EdgeInsets.only(
                        top: index == 0 ? 8 : 4,
                        bottom: 4,
                      ),
                      child: Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: GestureDetector(
                          onLongPress: () {
                            if (isFailed) {
                              _showRetryDialog(context, vm, message);
                            } else if (!isMine && message.content.isNotEmpty) {
                              _showAiBottomMenu(context, vm, message);
                            }
                          },
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.72,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isMine ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: Radius.circular(isMine ? 20 : 4),
                                bottomRight: Radius.circular(isMine ? 4 : 20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isMine ? 0.1 : 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message.latitude != null &&
                                    message.longitude != null)
                                  _buildLocationMessageCard(message, isMine)
                                else ...[
                                  if (message.attachments.isNotEmpty)
                                    ...message.attachments.map(
                                      (attachment) => _buildAttachmentTile(
                                        context,
                                        message,
                                        attachment,
                                      ),
                                    ),
                                  if (message.attachments.isNotEmpty &&
                                      message.content.isNotEmpty)
                                    const SizedBox(height: 8),
                                  if (message.content.isNotEmpty)
                                    Text(
                                      message.content,
                                      style: TextStyle(
                                        color: isMine
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                        height: 1.5,
                                      ),
                                    ),
                                ],
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: isMine
                                            ? Colors.white.withValues(alpha: 0.7)
                                            : AppColors.textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (isMine) ...[
                                      const SizedBox(width: 4),
                                      if (message.status == 'sending')
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white54,
                                            ),
                                          ),
                                        )
                                      else if (message.status == 'sent')
                                        const Icon(
                                          Icons.done_all_rounded,
                                          size: 14,
                                          color: Colors.white70,
                                        )
                                      else if (message.status == 'failed')
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          size: 14,
                                          color: Colors.redAccent,
                                        ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_selectedFiles.isNotEmpty)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: _selectedFiles
                        .map(
                          (file) => Stack(
                            children: [
                              _buildAttachmentPreview(file),
                              Positioned(
                                right: 2,
                                top: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedFiles.remove(file);
                                    });
                                  },
                                  child: const CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.black54,
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            // AI is thinking - floating icon
            if (vm.isGeneratingAi)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: _AiThinkingFloatingIcon(),
                ),
              ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Attachment button
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      icon: Icon(Icons.attach_file_outlined, size: 22),
                      color: AppColors.textSecondary,
                      onPressed: _pickAttachments,
                      padding: EdgeInsets.zero,
                      tooltip: 'Attach file',
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      icon: Icon(Icons.image_outlined, size: 22),
                      color: AppColors.textSecondary,
                      onPressed: _pickImage,
                      padding: EdgeInsets.zero,
                      tooltip: 'Add image',
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      icon: Icon(Icons.location_on_outlined, size: 22),
                      color: AppColors.textSecondary,
                      onPressed: _shareLocation,
                      padding: EdgeInsets.zero,
                      tooltip: 'Share location',
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Message input field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 44,
                        maxHeight: 120,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onTap: () {
                          if (_showEmoji) {
                            setState(() {
                              _showEmoji = false;
                            });
                          }
                        },
                        maxLines: null,
                        minLines: 1,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintMaxLines: 1,
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.emoji_emotions_outlined),
                            color: AppColors.textSecondary,
                            onPressed: _insertEmoji,
                            tooltip: 'Insert emoji',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Send button
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final text = _controller.text.trim();
                          if (text.isEmpty && _selectedFiles.isEmpty) return;
                          final attachmentFiles = _selectedFiles
                              .where((file) => file.path != null)
                              .map((file) => File(file.path!))
                              .toList();
                          final vm = context.read<ChatViewModel>();
                          await vm.sendMessage(
                            text,
                            attachments: attachmentFiles,
                          );
                          _controller.clear();
                          setState(() {
                            _selectedFiles.clear();
                          });
                          vm.markRead();
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showEmoji)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    _controller.text = _controller.text + emoji.emoji;
                  },
                  config: Config(
                    categoryViewConfig: const CategoryViewConfig(),
                    bottomActionBarConfig: const BottomActionBarConfig(
                      enabled: false,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),)
    );
  }
}

class _AiThinkingFloatingIcon extends StatefulWidget {
  const _AiThinkingFloatingIcon();

  @override
  State<_AiThinkingFloatingIcon> createState() => _AiThinkingFloatingIconState();
}

class _AiThinkingFloatingIconState extends State<_AiThinkingFloatingIcon>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _controller2 = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _controller2.repeat(reverse: true);
      }
    });

    _controller3 = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller3.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'AI is thinking',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DotWidget(animation: _controller1),
            const SizedBox(width: 4),
            _DotWidget(animation: _controller2),
            const SizedBox(width: 4),
            _DotWidget(animation: _controller3),
          ],
        ),
      ],
    );
  }
}

class _DotWidget extends StatelessWidget {
  final AnimationController animation;

  const _DotWidget({required this.animation});

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.6, end: 1.0).animate(animation),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class LocationMapScreen extends StatefulWidget {
  final LatLng destination;
  final LatLng? userLocation;
  final String otherName;

  const LocationMapScreen({
    super.key,
    required this.destination,
    this.userLocation,
    required this.otherName,
  });

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> with SingleTickerProviderStateMixin {
  late LatLng _currentReceiverLocation;
  late LatLng _previousReceiverLocation;
  bool _isRefreshing = false;
  DateTime? _lastUpdateTime;
  Timer? _refreshTimer;
  
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _currentReceiverLocation = widget.userLocation ?? widget.destination;
    _previousReceiverLocation = _currentReceiverLocation;
    _lastUpdateTime = DateTime.now();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    // Initial fetch if userLocation was null
    if (widget.userLocation == null) {
      _fetchLocation();
    }

    // Auto refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchLocation());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    if (_isRefreshing) return;
    
    if (mounted) {
      setState(() => _isRefreshing = true);
    }
    
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Location services are disabled.';
      }
      
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        throw 'Location permission denied.';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );
      
      final newLocation = LatLng(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _previousReceiverLocation = _currentReceiverLocation;
          _currentReceiverLocation = newLocation;
          _lastUpdateTime = DateTime.now();
          _isRefreshing = false;
        });
        
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  double _calculateDistance() {
    return Geolocator.distanceBetween(
      _currentReceiverLocation.latitude,
      _currentReceiverLocation.longitude,
      widget.destination.latitude,
      widget.destination.longitude,
    ) / 1000;
  }

  LatLng _interpolate(LatLng start, LatLng end, double fraction) {
    return LatLng(
      start.latitude + (end.latitude - start.latitude) * fraction,
      start.longitude + (end.longitude - start.longitude) * fraction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final distance = _calculateDistance();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (_isRefreshing)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
        ],
      ),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final movingLocation = _interpolate(_previousReceiverLocation, _currentReceiverLocation, _animation.value);
              
              return FlutterMap(
                options: MapOptions(
                  initialCenter: movingLocation,
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.collab_bot',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [movingLocation, widget.destination],
                        color: Colors.blue.withValues(alpha: 0.5),
                        strokeWidth: 4,
                        pattern: const StrokePattern.dotted(),
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Fixed Sender Marker
                      Marker(
                        point: widget.destination,
                        width: 150,
                        height: 70,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.otherName,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Icon(Icons.location_on, color: Colors.redAccent, size: 30),
                          ],
                        ),
                      ),
                      // Moving Receiver Marker
                      Marker(
                        point: movingLocation,
                        width: 150,
                        height: 80,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Icon(Icons.my_location, color: Colors.blueAccent, size: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          
          // Info Overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_walk, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '📍 ${distance.toStringAsFixed(2)} km away',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (_lastUpdateTime != null)
                          Text(
                            'Your location updated just now',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: _isRefreshing ? Colors.grey : Colors.blueAccent),
                    onPressed: _isRefreshing ? null : _fetchLocation,
                    tooltip: 'Refresh Location',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

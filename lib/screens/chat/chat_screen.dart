import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/message_model.dart';
import '../../view_model/chat_view_model.dart';

class ChatScreen extends StatelessWidget {
  final String chatId;
  final String otherName;
  final String? otherUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherName,
    this.otherUserId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(
        chatId: chatId,
        otherUserName: otherName,
        otherUserId: otherUserId,
      ),
      child: _ChatScreenContent(otherUserName: otherName),
    );
  }
}

class _ChatScreenContent extends StatefulWidget {
  final String otherUserName;
  const _ChatScreenContent({required this.otherUserName});

  @override
  State<_ChatScreenContent> createState() => _ChatScreenContentState();
}

class _ChatScreenContentState extends State<_ChatScreenContent> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Future<Position?>? _currentPositionFuture;
  List<PlatformFile> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _currentPositionFuture = _resolveCurrentPosition();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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
    const emoji = '😊';
    final selection = _controller.selection;
    final text = _controller.text;
    if (selection.isValid) {
      final newText = text.replaceRange(selection.start, selection.end, emoji);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + emoji.length,
        ),
      );
    } else {
      _controller.text = '$text$emoji';
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
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
        foregroundColor: Colors.black,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0] : 'U',
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Online',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade200),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
        elevation: 1,
      ),
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFEFF4FF),
      body: SafeArea(
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
                          onLongPress: isFailed
                              ? () => _showRetryDialog(context, vm, message)
                              : null,
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
                              color: isMine
                                  ? const Color(0xFF4B7CFD)
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMine ? 16 : 4),
                                bottomRight: Radius.circular(isMine ? 4 : 16),
                              ),
                              boxShadow: [
                                const BoxShadow(
                                  color: Color(0x05000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message.latitude != null && message.longitude != null)
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
                                            : Colors.black87,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        height: 1.4,
                                      ),
                                    ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: isMine
                                            ? Colors.white70
                                            : Colors.black45,
                                        fontSize: 10,
                                      ),
                                    ),
                                    if (isMine) ...[
                                      const SizedBox(width: 4),
                                      if (message.status == 'sending')
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white54,
                                                ),
                                          ),
                                        )
                                      else if (message.status == 'sent')
                                        Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white70,
                                        )
                                      else if (message.status == 'failed')
                                        Icon(
                                          Icons.error_outline,
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
            const Divider(height: 1),
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
                      icon: const Icon(Icons.attach_file_outlined),
                      color: Colors.grey.shade700,
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
                      icon: const Icon(Icons.image_outlined),
                      color: Colors.grey.shade700,
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
                      icon: const Icon(Icons.location_on_outlined),
                      color: Colors.grey.shade700,
                      onPressed: _shareLocation,
                      padding: EdgeInsets.zero,
                      tooltip: 'Share location',
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Message input field
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: 34,
                        maxHeight: 100,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        minLines: 1,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintMaxLines: 1,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.emoji_emotions_outlined),
                            color: Colors.grey.shade700,
                            onPressed: _insertEmoji,
                            tooltip: 'Insert emoji',
                            splashRadius: 20,
                          ),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Send button
                  SizedBox(
                    width: 40,
                    height: 40,
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
                            color: Colors.blue.shade600,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

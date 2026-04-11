import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../view_model/chat_view_model.dart';

class ChatScreen extends StatelessWidget {
  final String chatId;
  final String otherName;

  const ChatScreen({super.key, required this.chatId, required this.otherName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(chatId: chatId, otherUserName: otherName),
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
  List<PlatformFile> _selectedFiles = [];

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

  Widget _buildAttachmentPreview(PlatformFile file) {
    final isImage = file.extension != null && ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic']
        .contains(file.extension!.toLowerCase());
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

  Widget _buildAttachmentTile(BuildContext context, message, attachment) {
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
                child: const Icon(Icons.insert_drive_file, size: 32, color: Colors.grey),
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
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stateLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: downloaded ? Colors.green.shade700 : Colors.grey.shade700,
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

  void _showRetryDialog(BuildContext context, ChatViewModel vm, message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Failed'),
        content: const Text('This message failed to send. Tap "Retry" to send it again.'),
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
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: Text(widget.otherUserName.isNotEmpty ? widget.otherUserName[0] : 'U'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Online', style: TextStyle(fontSize: 12, color: Colors.green.shade200)),
              ],
            ),
          ],
        ),
        centerTitle: false,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF6F8FB),
      body: Column(
        children: [
          if (vm.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: false,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: vm.messages.length,
                itemBuilder: (context, index) {
                  final message = vm.messages[index];
                  final currentUser = Supabase.instance.client.auth.currentUser;
                  final isMine = currentUser != null && message.senderId == currentUser.id;
                  final isFailed = isMine && message.status == 'failed';
                  
                  return Padding(
                    padding: EdgeInsets.only(top: index == 0 ? 8 : 4, bottom: 4),
                    child: Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: isFailed
                            ? () => _showRetryDialog(context, vm, message)
                            : null,
                        child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMine ? const Color(0xFF4B7CFD) : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMine ? 16 : 4),
                            bottomRight: Radius.circular(isMine ? 4 : 16),
                          ),
                          boxShadow: [
                            const BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.attachments.isNotEmpty)
                              ...message.attachments.map((attachment) => _buildAttachmentTile(context, message, attachment)),
                            if (message.attachments.isNotEmpty && message.content.isNotEmpty)
                              const SizedBox(height: 8),
                            if (message.content.isNotEmpty)
                              Text(
                                message.content,
                                style: TextStyle(color: isMine ? Colors.white : Colors.black87, fontSize: 14),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: isMine ? Colors.white70 : Colors.black45,
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
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                                      ),
                                    )
                                  else if (message.status == 'sent')
                                    Icon(Icons.check, size: 14, color: Colors.white70)
                                  else if (message.status == 'failed')
                                    Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
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
                      .map((file) => Stack(
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
                                    child: Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ))
                      .toList(),
                ),
              ),
            ),
          const Divider(height: 1),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                // Attachment button
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    icon: const Icon(Icons.attach_file),
                    color: Colors.grey.shade700,
                    onPressed: _pickAttachments,
                    padding: EdgeInsets.zero,
                    tooltip: 'Attach file',
                  ),
                ),
                const SizedBox(width: 8),
                // Message input field
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: 44,
                      maxHeight: 120,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      minLines: 1,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                        await vm.sendMessage(text, attachments: attachmentFiles);
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
                        child: const Icon(Icons.send, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/models/message_model.dart';
import '../data/models/attachment_model.dart';
import '../data/services/message_service.dart';
import '../local_db/local_message_db.dart';

class ChatViewModel extends ChangeNotifier {
  final String chatId;
  final String otherUserName;
  final String? otherUserId;
  final SupabaseClient _supabase = Supabase.instance.client;
  late final MessageService _messageService;
  final Uuid _uuid = const Uuid();

  bool isLoading = false;
  bool isDownloadingAttachment = false;
  String? errorMessage;
  List<LocalMessage> messages = [];
  final Set<String> _messageIds = {};
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;

  ChatViewModel({
    required this.chatId,
    required this.otherUserName,
    this.otherUserId,
  }) {
    _messageService = MessageService(_supabase);
    subscribeRealtime();
    loadMessages();
  }

  Future<void> loadMessages() async {
    isLoading = true;
    notifyListeners();
    try {
      final localMessages = await LocalMessageDb.instance.getMessagesForChat(chatId);
      messages = localMessages;
      _messageIds.addAll(messages.map((m) => m.id));

      final currentUser = _supabase.auth.currentUser;
      final remoteMessages = await _messageService.fetchLastMessages(chatId, limit: 100);
      print('📡 Remote fetch loaded ${remoteMessages.length} messages for chat $chatId');
      for (final remote in remoteMessages) {
        final exists = messages.any((m) => m.id == remote.id);
        if (!exists && remote.senderId != currentUser?.id) {
          print('📥 Loading remote message ${remote.id} from ${remote.senderId}');
          
          // Fetch attachments for this message
          final attachments = await _messageService.fetchAttachmentsForMessage(remote.id);
          final localMessage = _localMessageFromRemote(remote.copyWith(attachments: attachments));
          
          print('💾 Saving to local DB...');
          await LocalMessageDb.instance.saveMessage(localMessage);
          messages.add(localMessage);
          
          // Download all attachments BEFORE deleting from Supabase
          if (localMessage.attachments.isNotEmpty) {
            print('📥 Downloading ${localMessage.attachments.length} attachments...');
            for (final attachment in localMessage.attachments) {
              try {
                await downloadAttachment(localMessage, attachment);
                print('✅ Downloaded attachment: ${attachment.fileName}');
              } catch (e) {
                print('⚠️ Failed to download attachment ${attachment.fileName}: $e');
              }
            }
          }
          
          print('🗑️ All data downloaded, deleting from Supabase...');
          await _messageService.deleteMessageFromSupabase(remote.id);
          print('✅ Deleted from Supabase');
        }
      }
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _messageIds
        ..clear()
        ..addAll(messages.map((m) => m.id));
    } catch (e) {
      errorMessage = 'Failed to read messages: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content, {List<File>? attachments}) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      errorMessage = 'User signed out';
      notifyListeners();
      return;
    }
    if (content.trim().isEmpty && (attachments == null || attachments.isEmpty)) {
      return;
    }

    final tempId = _uuid.v4();
    final pendingAttachments = attachments?.map((file) {
      final fileName = p.basename(file.path);
      return AttachmentModel(
        id: _uuid.v4(),
        messageId: tempId,
        fileUrl: file.path,
        fileName: fileName,
        extension: p.extension(fileName).toLowerCase(),
        downloadState: AttachmentDownloadState.downloaded.name,
        localPath: file.path,
        createdAt: DateTime.now(),
      );
    }).toList();

    final pendingMessage = LocalMessage(
      id: tempId,
      chatId: chatId,
      senderId: currentUser.id,
      content: content.trim(),
      createdAt: DateTime.now(),
      attachments: pendingAttachments ?? [],
      status: MessageStatus.sending.name,
    );

    messages.add(pendingMessage);
    _messageIds.add(pendingMessage.id);
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    await LocalMessageDb.instance.saveMessage(pendingMessage);
    notifyListeners();

    try {
      if (otherUserId != null) {
        await _messageService.ensureParticipant(chatId, otherUserId!);
      }
      final sent = await _messageService.sendMessage(
        chatId: chatId,
        senderId: currentUser.id,
        content: content.trim(),
        attachments: attachments,
        messageId: tempId,
      );

      final sentMessage = pendingMessage.copyWith(
        content: sent.content,
        createdAt: sent.createdAt,
        attachments: sent.attachments,
        status: MessageStatus.sent.name,
      );
      await LocalMessageDb.instance.updateMessage(sentMessage);
      _replaceMessageInList(sentMessage);
      notifyListeners();
    } catch (e) {
      final failedMessage = pendingMessage.copyWith(status: MessageStatus.failed.name);
      await LocalMessageDb.instance.updateMessage(failedMessage);
      _replaceMessageInList(failedMessage);
      errorMessage = 'Could not send message: $e';
      notifyListeners();
    }
  }

  void _replaceMessageInList(LocalMessage message) {
    final index = messages.indexWhere((item) => item.id == message.id);
    if (index >= 0) {
      messages[index] = message;
    } else {
      messages.add(message);
    }
    _messageIds.add(message.id);
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> retryFailedMessage(LocalMessage failedMessage) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    final retryingMessage = failedMessage.copyWith(status: MessageStatus.sending.name);
    await LocalMessageDb.instance.updateMessage(retryingMessage);
    _replaceMessageInList(retryingMessage);
    notifyListeners();

    try {
      final sent = await _messageService.sendMessage(
        chatId: chatId,
        senderId: currentUser.id,
        content: failedMessage.content,
        messageId: failedMessage.id,
      );

      final sentMessage = retryingMessage.copyWith(
        content: sent.content,
        createdAt: sent.createdAt,
        attachments: sent.attachments,
        status: MessageStatus.sent.name,
      );
      await LocalMessageDb.instance.updateMessage(sentMessage);
      _replaceMessageInList(sentMessage);
      notifyListeners();
    } catch (e) {
      final failedMsg = retryingMessage.copyWith(status: MessageStatus.failed.name);
      await LocalMessageDb.instance.updateMessage(failedMsg);
      _replaceMessageInList(failedMsg);
      errorMessage = 'Retry failed: $e';
      notifyListeners();
    }
  }

  void subscribeRealtime() {
    _realtimeSubscription?.cancel();

    final stream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId);

    print('🔌 Realtime stream subscribe started for chat $chatId');
    _realtimeSubscription = stream.listen((rows) async {
      print('🔔 Realtime stream event rows count: ${rows.length}');
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('⚠️ Realtime event dropped because currentUser is null');
        return;
      }

      for (final raw in rows) {
        try {
          final row = Map<String, dynamic>.from(raw as Map);
          final senderId = row['sender_id'] as String?;
          final messageId = row['id'] as String?;
          if (senderId == null || messageId == null) {
            print('❌ Realtime row missing required fields: $row');
            continue;
          }
          if (senderId == currentUser.id) continue;
          if (_messageIds.contains(messageId)) continue;

          final remote = MessageModel.fromJson(row);
          final attachments = await _messageService.fetchAttachmentsForMessage(remote.id);
          final message = _localMessageFromRemote(remote.copyWith(attachments: attachments));

          print('📥 Received message ${message.id} from ${message.senderId}, saving to local DB...');
          await LocalMessageDb.instance.saveMessage(message);
          print('✅ Saved to local DB');

          if (message.attachments.isNotEmpty) {
            print('📥 Downloading ${message.attachments.length} attachments...');
            for (final attachment in message.attachments) {
              try {
                await downloadAttachment(message, attachment);
                print('✅ Downloaded attachment: ${attachment.fileName}');
              } catch (e) {
                print('⚠️ Failed to download attachment ${attachment.fileName}: $e');
              }
            }
          }

          print('🗑️ All attachments processed, now deleting from Supabase...');
          await _messageService.deleteMessageFromSupabase(message.id);
          print('✅ Deleted from Supabase');

          _messageIds.add(message.id);
          messages.add(message);
        } catch (itemError) {
          print('❌ Error processing realtime row: $itemError');
        }
      }
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      notifyListeners();
    }, onError: (e) {
      errorMessage = 'Realtime error: $e';
      print('❌ Realtime stream error: $e');
      notifyListeners();
    });
  }

  Future<String?> downloadAttachment(LocalMessage message, AttachmentModel attachment) async {
    if (attachment.isDownloaded && attachment.localPath != null) {
      final file = File(attachment.localPath!);
      if (await file.exists()) {
        print('📦 File already downloaded: ${attachment.localPath}');
        return attachment.localPath;
      }
    }
    isDownloadingAttachment = true;
    notifyListeners();
    try {
      print('🔄 Downloading attachment: ${attachment.fileName}');
      final localFile = await _messageService.attachmentService.downloadAttachmentToLocal(chatId, attachment);
      
      if (!await localFile.exists()) {
        throw Exception('Downloaded file does not exist at ${localFile.path}');
      }
      
      print('✅ Attachment downloaded to: ${localFile.path}');
      final updatedAttachment = attachment.copyWith(
        localPath: localFile.path,
        downloadState: AttachmentDownloadState.downloaded.name,
      );
      await _updateAttachmentForMessage(message, updatedAttachment);
      return localFile.path;
    } catch (e) {
      print('❌ Download failed: $e');
      final failedAttachment = attachment.copyWith(downloadState: AttachmentDownloadState.failed.name);
      await _updateAttachmentForMessage(message, failedAttachment);
      errorMessage = 'Attachment download failed: $e';
      notifyListeners();
      return null;
    } finally {
      isDownloadingAttachment = false;
      notifyListeners();
    }
  }

  Future<String?> openAttachment(LocalMessage message, AttachmentModel attachment) async {
    try {
      print('🎯 Opening attachment: ${attachment.fileName}');
      final localPath = await downloadAttachment(message, attachment);
      if (localPath == null) {
        errorMessage = 'Failed to download attachment';
        notifyListeners();
        return null;
      }
      
      final file = File(localPath);
      if (!await file.exists()) {
        errorMessage = 'File not found: $localPath';
        notifyListeners();
        return null;
      }
      
      print('📂 Opening file: $localPath (size: ${await file.length()} bytes)');
      final result = await OpenFile.open(localPath);
      print('📤 OpenFile result: ${result.message}');
      
      if (result.type != ResultType.done) {
        errorMessage = 'Could not open file: ${result.message}';
        notifyListeners();
        return null;
      }
      
      return localPath;
    } catch (e) {
      print('❌ Open attachment error: $e');
      errorMessage = 'Could not open attachment: $e';
      notifyListeners();
      return null;
    }
  }

  LocalMessage _localMessageFromRemote(MessageModel remote) {
    final attachments = remote.attachments
        .map((attachment) => attachment.copyWith(downloadState: AttachmentDownloadState.notDownloaded.name, localPath: null))
        .toList();
    return LocalMessage(
      id: remote.id,
      chatId: remote.chatId,
      senderId: remote.senderId,
      content: remote.content,
      createdAt: remote.createdAt,
      attachments: attachments,
      status: MessageStatus.sent.name,
    );
  }

  Future<void> _updateAttachmentForMessage(LocalMessage message, AttachmentModel updatedAttachment) async {
    final updatedAttachments = message.attachments
        .map((item) => item.id == updatedAttachment.id ? updatedAttachment : item)
        .toList();
    final updatedMessage = message.copyWith(attachments: updatedAttachments);
    await LocalMessageDb.instance.updateMessage(updatedMessage);
    final index = messages.indexWhere((item) => item.id == updatedMessage.id);
    if (index >= 0) {
      messages[index] = updatedMessage;
    }
    notifyListeners();
  }

  Future<void> markRead() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;
    await LocalMessageDb.instance.setLastReadAt(chatId, currentUser.id, DateTime.now());
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}

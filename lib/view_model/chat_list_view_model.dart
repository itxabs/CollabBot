import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/chat_presence_service.dart';
import '../data/models/chat_model.dart';
import '../data/models/message_model.dart';
import '../data/models/attachment_model.dart';
import '../data/repositories/chat_repository.dart';
import '../data/services/chat_service.dart';
import '../data/services/message_service.dart';
import '../local_db/local_message_db.dart';

class ChatListViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final ChatRepository _chatRepository;
  bool isLoading = false;
  String? errorMessage;
  bool hasSyncError = false;
  String searchQuery = '';
  List<ChatSummary> _chats = [];
  List<ChatSummary> get chats => _chats;
  set chats(List<ChatSummary> value) {
    _chats = List.from(value);
    _chats.sort((a, b) {
      if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
      if (a.lastMessageAt == null) return 1;
      if (b.lastMessageAt == null) return -1;
      return b.lastMessageAt!.compareTo(a.lastMessageAt!);
    });
  }
  bool _disposed = false;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;
  final Set<String> _knownMessageIds = <String>{};
  bool _isRealtimePrimed = false;

  ChatListViewModel() {
    _chatRepository = ChatRepository(ChatService(_supabase));
    loadChats();
  }

  @override
  void dispose() {
    _disposed = true;
    _messagesSubscription?.cancel();
    super.dispose();
  }

  void safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  List<ChatSummary> get filteredChats {
    if (searchQuery.isEmpty) return chats;
    final query = searchQuery.toLowerCase();
    return chats.where((chat) {
      return chat.otherUserName.toLowerCase().contains(query) ||
          (chat.lastMessage?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void updateSearchQuery(String query) {
    searchQuery = query;
    safeNotifyListeners();
  }

  Future<void> loadChats() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      errorMessage = 'User is not logged in';
      safeNotifyListeners();
      return;
    }
    final currentUserId = currentUser.id;

    // Load from cache first
    try {
      final cached = await LocalMessageDb.instance.getUserChats(currentUserId);
      if (cached.isNotEmpty) {
        chats = cached;
        safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached chats: $e');
    }

    // Only show full loading spinner if we don't have cached chats
    isLoading = chats.isEmpty;
    errorMessage = null;
    safeNotifyListeners();

    try {
      await _hydrateChats(currentUserId);
      _ensureRealtimeSubscription(currentUserId);
      hasSyncError = false;
    } catch (e) {
      if (_disposed) return;
      debugPrint('Failed to sync chats with server: $e');
      if (chats.isEmpty) {
        errorMessage = 'Failed to load chats. ${e.toString()}';
      } else {
        hasSyncError = true;
      }
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  Future<void> deleteChat(String chatId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not logged in');
    }

    isLoading = true;
    errorMessage = null;
    safeNotifyListeners();

    try {
      await _chatRepository.leaveChat(chatId, currentUser.id);
      chats.removeWhere((chat) => chat.chatId == chatId);
      await LocalMessageDb.instance.saveUserChats(currentUser.id, chats);
    } catch (e) {
      if (_disposed) return;
      errorMessage = 'Failed to delete chat. ${e.toString()}';
      rethrow;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  Future<void> _hydrateChats(String currentUserId) async {
    final list = await _chatRepository.getUserChats(currentUserId);

    final enriched = <ChatSummary>[];
    for (final chat in list) {
      if (_disposed) return;
      final unread = await LocalMessageDb.instance.getUnreadCount(
        chat.chatId,
        currentUserId,
      );
      final localLast = await LocalMessageDb.instance.getLastMessage(chat.chatId);
      
      String? displayLastMessage = chat.lastMessage;
      DateTime? displayLastMessageAt = chat.lastMessageAt;
      String? displayLastMessageSenderId = chat.lastMessageSenderId;

      if (localLast != null) {
        if (displayLastMessageAt == null || 
            localLast.createdAt.isAfter(displayLastMessageAt)) {
          displayLastMessage = localLast.content;
          displayLastMessageAt = localLast.createdAt;
          displayLastMessageSenderId = localLast.senderId;
        }
      }

      final isMine = displayLastMessageSenderId == currentUserId;

      enriched.add(
        ChatSummary(
          chatId: chat.chatId,
          otherUserId: chat.otherUserId,
          otherUserName: chat.otherUserName,
          otherUserAvatarUrl: chat.otherUserAvatarUrl,
          otherUserRole: chat.otherUserRole,
          lastMessage: displayLastMessage,
          lastMessageAt: displayLastMessageAt,
          lastMessageSenderId: displayLastMessageSenderId,
          isLastMessageMine: isMine,
          hasUnread: unread > 0,
        ),
      );
    }

    chats = enriched;
    await LocalMessageDb.instance.saveUserChats(currentUserId, chats);
  }

  void _ensureRealtimeSubscription(String currentUserId) {
    if (_messagesSubscription != null) return;

    final messageService = MessageService(_supabase);

    _messagesSubscription = _chatRepository.subscribeToAllMessages().listen(
      (rows) async {
        if (_disposed) return;

        if (!_isRealtimePrimed) {
          for (final row in rows) {
            final id = row['id'] as String?;
            if (id != null) _knownMessageIds.add(id);
          }
          _isRealtimePrimed = true;
          return;
        }

        bool hasRelevantIncoming = false;
        for (final row in rows) {
          final messageId = row['id'] as String?;
          if (messageId == null || _knownMessageIds.contains(messageId)) {
            continue;
          }
          _knownMessageIds.add(messageId);

          final senderId = row['sender_id'] as String?;
          final chatId = row['chat_id'] as String?;
          if (senderId == null || chatId == null) {
            continue;
          }

          if (senderId == currentUserId) {
            continue;
          }

          final isLocalParticipant = chats.any((c) => c.chatId == chatId);
          final belongsToCurrentUser = isLocalParticipant || await _chatRepository.isParticipant(
            chatId,
            currentUserId,
          );
          if (!belongsToCurrentUser) continue;

          // If the user is currently viewing this chat inside the ChatScreen,
          // let the ChatViewModel handle saving/deleting to avoid race conditions.
          if (ChatPresenceService.instance.activeChatId == chatId) {
            hasRelevantIncoming = true;
            continue;
          }

          // Save the message locally and cleanup Supabase
          try {
            final remote = MessageModel.fromJson(row);
            final attachments = await messageService.fetchAttachmentsForMessage(remote.id);
            
            final localAttachments = attachments
                .map((attachment) => attachment.copyWith(
                      downloadState: AttachmentDownloadState.notDownloaded.name,
                      localPath: null,
                    ))
                .toList();

            final localMsg = LocalMessage(
              id: remote.id,
              chatId: remote.chatId,
              senderId: remote.senderId,
              content: remote.content,
              createdAt: remote.createdAt,
              attachments: localAttachments,
              latitude: remote.latitude,
              longitude: remote.longitude,
              status: MessageStatus.sent.name,
            );

            debugPrint('📥 ChatList Realtime: Syncing new message ${localMsg.id} to local DB...');
            await LocalMessageDb.instance.saveMessage(localMsg);

            // Fetch attachments in background
            if (localMsg.attachments.isNotEmpty) {
              for (final attachment in localMsg.attachments) {
                try {
                  await messageService.attachmentService.downloadAttachmentToLocal(chatId, attachment);
                } catch (e) {
                  debugPrint('Failed to download attachment in background: $e');
                }
              }
            }

            debugPrint('🗑️ ChatList Realtime: Deleting synced message ${remote.id} from Supabase...');
            await messageService.deleteMessageFromSupabase(remote.id);
          } catch (e) {
            debugPrint('Error syncing realtime message on ChatList: $e');
          }

          hasRelevantIncoming = true;
        }

        if (hasRelevantIncoming && !_disposed) {
          await _hydrateChats(currentUserId);
          safeNotifyListeners();
        }
      },
      onError: (e) {
        if (_disposed) return;
        debugPrint('Realtime chat updates failed: $e');
        if (chats.isEmpty) {
          errorMessage = 'Realtime chat updates failed: $e';
        } else {
          hasSyncError = true;
        }
        safeNotifyListeners();
      },
    );
  }
}

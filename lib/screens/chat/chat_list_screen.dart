import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/routes.dart';
import '../../view_model/chat_list_view_model.dart';
import '../../data/models/chat_model.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatListViewModel(),
      child: const _ChatListContent(),
    );
  }
}

class _ChatListContent extends StatelessWidget {
  const _ChatListContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatListViewModel>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Messages',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vm.filteredChats.length} conversations',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.newChat),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: vm.updateSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                    suffixIcon: vm.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey.shade500,
                            ),
                            onPressed: () => vm.updateSearchQuery(''),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: vm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : vm.errorMessage != null
                  ? Center(child: Text(vm.errorMessage!))
                  : vm.filteredChats.isEmpty
                  ? const Center(
                      child: Text('No chats yet. Start a conversation.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: vm.filteredChats.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final chat = vm.filteredChats[index];
                        return ChatTile(chat: chat);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatTile extends StatelessWidget {
  final ChatSummary chat;
  const ChatTile({required this.chat, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.chat,
        arguments: {
          'chatId': chat.chatId,
          'otherName': chat.otherUserName,
          'otherUserId': chat.otherUserId,
        },
      ),
      onLongPress: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete chat'),
            content: const Text('Delete this conversation from your chats?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

        final vm = context.read<ChatListViewModel>();
        try {
          await vm.deleteChat(chat.chatId);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Chat deleted')));
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not delete chat: $e')));
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                chat.otherUserName.isNotEmpty ? chat.otherUserName[0] : 'U',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.otherUserName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.lastMessage ?? 'Say hi!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (chat.lastMessageAt != null)
                  Text(
                    _formatTime(chat.lastMessageAt!),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                const SizedBox(height: 8),
                if (chat.hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'New',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (now.difference(dt).inDays < 7) {
      return '${dt.weekday == 1
          ? 'Mon'
          : dt.weekday == 2
          ? 'Tue'
          : dt.weekday == 3
          ? 'Wed'
          : dt.weekday == 4
          ? 'Thu'
          : dt.weekday == 5
          ? 'Fri'
          : dt.weekday == 6
          ? 'Sat'
          : 'Sun'}';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

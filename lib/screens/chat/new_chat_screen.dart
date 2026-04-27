import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/routes.dart';
import '../../view_model/new_chat_view_model.dart';

class NewChatScreen extends StatelessWidget {
  const NewChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NewChatViewModel(),
      child: const _NewChatContent(),
    );
  }
}

class _NewChatContent extends StatefulWidget {
  const _NewChatContent();

  @override
  State<_NewChatContent> createState() => _NewChatContentState();
}

class _NewChatContentState extends State<_NewChatContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NewChatViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Start New Chat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => vm.search(_searchController.text.trim()),
                ),
              ),
              onSubmitted: (value) => vm.search(value.trim()),
            ),
          ),
          if (vm.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (vm.errorMessage != null)
            Expanded(child: Center(child: Text(vm.errorMessage!)))
          else
            Expanded(
              child: ListView.separated(
                itemCount: vm.users.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (context, index) {
                  final user = vm.users[index];
                  return ListTile(
                    title: Text(user['full_name'] as String? ?? 'Unknown'),
                    subtitle: Text(user['email'] as String? ?? ''),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      try {
                        final chatId = await vm.createChatWithUser(user['id'] as String);
                        if (!mounted) return;
                        Navigator.pushReplacementNamed(context, AppRoutes.chat, arguments: {
                          'chatId': chatId,
                          'otherName': user['full_name'] as String? ?? 'Chat',
                          'otherUserId': user['id'] as String,
                          'otherUserRole': user['role'] as String?,
                        });
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not open chat: $e')));
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

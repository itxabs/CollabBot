import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/routes.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/new_chat_view_model.dart';
import '../../widgets/user_avatar_widget.dart';
import '../../widgets/user_role_icon.dart';
import '../../widgets/custom_search_bar.dart';

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Premium Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textPrimary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start New Chat', style: AppTextStyles.h2),
                      Text(
                        'Find someone to collaborate with!',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Enhanced Search Bar
            CustomSearchBar(
              controller: _searchController,
              hintText: 'Search for collaborators...',
              onChanged: vm.search,
            ),
            const SizedBox(height: 16),

            if (vm.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (vm.errorMessage != null)
              Expanded(child: Center(child: Text(vm.errorMessage!)))
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: vm.users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = vm.users[index];
                    return _buildUserCard(context, user, vm);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(
      BuildContext context, Map<String, dynamic> user, NewChatViewModel vm) {
    final String name = user['full_name'] as String? ?? 'Unknown';
    final String email = user['email'] as String? ?? '';
    final String? role = user['role'] as String?;
    final String? avatarUrl = user['avatar_url'] as String?;

    return GestureDetector(
      onTap: () async {
        try {
          final chatId = await vm.createChatWithUser(user['id'] as String);
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRoutes.chat, arguments: {
            'chatId': chatId,
            'otherName': name,
            'otherUserId': user['id'] as String,
            'otherUserRole': role,
          });
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open chat: $e')));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            UserAvatarWidget(
              name: name,
              avatarUrl: avatarUrl,
              radius: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (role != null) ...[
                        const SizedBox(width: 8),
                        UserRoleIcon(role: role),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role ?? email,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

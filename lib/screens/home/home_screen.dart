import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/home_view_model.dart';
import '../../view_model/auth_view_model.dart';
import '../../data/models/question_model.dart';
import '../questions/question_detail_screen.dart';
import '../main_navigation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        return ChangeNotifierProvider(
          create: (_) =>
              HomeViewModel(currentUserId: authViewModel.currentUser?.userId),
          child: _HomeContent(authViewModel: authViewModel),
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  final AuthViewModel authViewModel;

  const _HomeContent({required this.authViewModel});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);
    final userName = authViewModel.currentUser?.name ?? 'User';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => viewModel.refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, $userName!', style: AppTextStyles.h2),
                      Text(
                        'Ready to learn today?',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1.5),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.05),
                      backgroundImage: authViewModel.currentUser?.avatarUrl != null && 
                                      authViewModel.currentUser!.avatarUrl!.isNotEmpty
                          ? NetworkImage(authViewModel.currentUser!.avatarUrl!)
                          : null,
                      child: authViewModel.currentUser?.avatarUrl == null || 
                             authViewModel.currentUser!.avatarUrl!.isEmpty
                          ? Text(
                              (authViewModel.currentUser?.name.isNotEmpty ?? false)
                                  ? authViewModel.currentUser!.name[0].toUpperCase()
                                  : '',
                              style: AppTextStyles.h3.copyWith(color: AppColors.primary, fontSize: 18),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Points',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${viewModel.points}',
                                style: AppTextStyles.h1.copyWith(
                                  color: Colors.white,
                                  fontSize: 36,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified Skills',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${viewModel.verifiedSkillsCount}',
                                style: AppTextStyles.h1.copyWith(
                                  color: Colors.white,
                                  fontSize: 36,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Top 5% of Learners',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text('Quick Actions', style: AppTextStyles.h3),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(
                    context,
                    Icons.search,
                    'Find Match',
                    Colors.blue,
                    () {
                      mainNavigationKey.currentState?.switchToTab(1);
                    },
                  ),
                  _buildQuickAction(
                    context,
                    Icons.auto_awesome,
                    'CollabAI',
                    Colors.orange,
                    () {},
                  ),
                  _buildQuickAction(
                    context,
                    Icons.help_outline,
                    'Questions',
                    Colors.redAccent,
                    () => Navigator.pushNamed(context, '/questions'),
                  ),
                  _buildQuickAction(
                    context,
                    Icons.event,
                    'Events',
                    Colors.green,
                    () {
                      mainNavigationKey.currentState?.switchToTab(3);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Latest Questions', style: AppTextStyles.h3),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/questions'),
                    child: Text('See All', style: AppTextStyles.link),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (viewModel.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (viewModel.latestQuestions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'No questions asked yet.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: viewModel.latestQuestions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final question = viewModel.latestQuestions[index];
                    return _buildQuestionCard(question, context);
                  },
                ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Upcoming Events', style: AppTextStyles.h3),
                  GestureDetector(
                    onTap: () {
                      mainNavigationKey.currentState?.switchToTab(3);
                    },
                    child: Row(
                      children: [
                        Text('See all', style: AppTextStyles.link),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (viewModel.upcomingEvents.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'No upcoming events right now.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 128,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: viewModel.upcomingEvents.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final event = viewModel.upcomingEvents[index];
                      return _buildEventPreviewCard(event);
                    },
                  ),
                ),
            ],
          ),
        ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/ask_question');
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.help_outline, color: Colors.white),
        label: const Text(
          'Ask Question',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuestionDetailScreen(question: question),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    question.authorName.isNotEmpty ? question.authorName[0].toUpperCase() : '?',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.authorName,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (question.authorRole != null && question.authorRole!.isNotEmpty)
                        Text(
                          question.authorRole!,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 10),
                        ),
                    ],
                  ),
                ),
                Text(
                  question.formattedDate,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.title,
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatBadge(Icons.thumb_up_outlined, '${question.upvotes}'),
                const SizedBox(width: 16),
                _buildStatBadge(Icons.chat_bubble_outline, '${question.answerCount}'),
                const Spacer(),
                if (question.tags.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      question.tags.first,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEventPreviewCard(HomeEventPreview event) {
    return Container(
      width: 182,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.dateTimeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '${event.attendingCount} attending',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

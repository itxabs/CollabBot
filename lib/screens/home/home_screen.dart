import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/home_view_model.dart';
import '../../core/widgets/primary_button.dart'; // Reuse button if needed, or create cards

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: const _HomeContent(),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, Abdul!', style: AppTextStyles.h2),
                      Text('Ready to learn today?', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Points Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF6366F1)], // Indigo to Purple
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Points', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      '${viewModel.points}', 
                      style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 36),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Top 5% of Learners',
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Quick Actions
              Text('Quick Actions', style: AppTextStyles.h3),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(Icons.search, 'Find Match', Colors.blue),
                  _buildQuickAction(Icons.auto_awesome, 'CollabAI', Colors.orange),
                  _buildQuickAction(Icons.leaderboard, 'Rankings', Colors.purple),
                  _buildQuickAction(Icons.event, 'Events', Colors.green),
                ],
              ),
              const SizedBox(height: 32),

              // Suggested Mentors
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Suggested for You', style: AppTextStyles.h3),
                  Text('See All', style: AppTextStyles.link),
                ],
              ),
              const SizedBox(height: 16),
              
              if (viewModel.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: viewModel.suggestedMentors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final mentor = viewModel.suggestedMentors[index];
                    return _buildMentorCard(mentor);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.bodyMedium.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMentorCard(Mentor mentor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.background,
            child: Text(mentor.name[0], style: AppTextStyles.h3.copyWith(fontSize: 18)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mentor.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                Text('${mentor.role} at ${mentor.company}', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

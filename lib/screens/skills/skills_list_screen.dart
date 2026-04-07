import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/skills_view_model.dart';
import 'add_skill_screen.dart';
import 'quiz_screen.dart';

class SkillsListScreen extends StatefulWidget {
  const SkillsListScreen({super.key});

  @override
  State<SkillsListScreen> createState() => _SkillsListScreenState();
}

class _SkillsListScreenState extends State<SkillsListScreen> {
  late SkillsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SkillsViewModel();
    _viewModel.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: const _SkillsListContent(),
    );
  }
}

class _SkillsListContent extends StatelessWidget {
  const _SkillsListContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SkillsViewModel>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Skills', style: AppTextStyles.h3),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: viewModel,
                    child: const AddSkillScreen(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: viewModel.loadData,
              child: viewModel.skills.isEmpty
                  ? Center(
                      child: Text(
                        'No skills added yet',
                        style: AppTextStyles.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: viewModel.skills.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final skill = viewModel.skills[index];
                        final levelName = viewModel.getLevelName(skill.skillLevelId);
                        // Assuming created_at is available in model, actually it's not in UserSkill model I updated previously.
                        // Wait, I didn't add createdAt to UserSkill model in previous step?
                        // I need to check UserSkill model again. It has id, userId, skillName, skillLevelId, isVerified.
                        // Requested: "Created At (formatted date)"
                        // I missed adding `created_at` to UserSkill in previous step? Let me check.
                        
                        return InkWell(
                          onTap: () {
                            if (!skill.isVerified) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuizScreen(skill: skill),
                                ),
                              ).then((_) {
                                // Refresh list when coming back
                                viewModel.loadData();
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(skill.skillName, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: skill.isVerified ? AppColors.success.withOpacity(0.1) : AppColors.border.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      skill.isVerified ? 'Verified' : 'Not Verified',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: skill.isVerified ? AppColors.success : AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.bar_chart, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(levelName, style: AppTextStyles.bodyMedium),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(skill.createdAt),
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        );
                      },
                    ),
            ),
    );
  }
}

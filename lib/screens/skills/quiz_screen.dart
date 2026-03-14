import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/profile_models.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/profile_service.dart';
import '../../view_model/quiz_view_model.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatelessWidget {
  final UserSkill skill;

  const QuizScreen({super.key, required this.skill});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizViewModel(
        geminiService: GeminiService(),
        profileRepository: ProfileRepositoryImpl(
          ProfileService(Supabase.instance.client),
        ),
      )..startQuiz(skill),
      child: const _QuizContent(),
    );
  }
}

class _QuizContent extends StatelessWidget {
  const _QuizContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<QuizViewModel>(context);

    if (viewModel.isLoading && viewModel.questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Skill Verification', style: AppTextStyles.h3),
          backgroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          leading: const BackButton(color: AppColors.textPrimary),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating detailed quiz with AI...'),
            ],
          ),
        ),
      );
    }

    if (viewModel.errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Error', style: AppTextStyles.h3),
          backgroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          leading: const BackButton(color: AppColors.textPrimary),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  viewModel.errorMessage!,
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => viewModel.retryQuiz(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

     // Listen for submission completion to navigate
    if (viewModel.isSubmitted && !viewModel.isLoading) {
       // Use addPostFrameCallback to avoid navigation during build
       WidgetsBinding.instance.addPostFrameCallback((_) {
         Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuizResultScreen(
              viewModel: viewModel,
              onBackToSkills: () {
                Navigator.pop(context); // Close result
                // Navigator.pop(context); // Close quiz (handled by replacement)
              },
            ),
          ),
        );
       });
    }

    final question = viewModel.questions[viewModel.currentQuestionIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Quiz: ${viewModel.currentSkill?.skillName}', style: AppTextStyles.h3.copyWith(fontSize: 18)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: BackButton(
          color: AppColors.textPrimary,
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Quit Quiz?'),
                content: const Text('Progress will be lost.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Quit')),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: viewModel.progressPercentage,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Question ${viewModel.currentQuestionIndex + 1} / ${viewModel.totalQuestions}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              
              // Question
              Text(
                question['question'],
                style: AppTextStyles.h2.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 32),

              // Options
              Expanded(
                child: ListView.separated(
                  itemCount: (question['options'] as List).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (ctx, index) {
                    final option = question['options'][index] as String;
                    final isSelected = viewModel.selectedOption == option;

                    return InkWell(
                      onTap: () => viewModel.selectOption(option),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  width: 2,
                                ),
                                color: isSelected ? AppColors.primary : Colors.transparent,
                              ),
                              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Next Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: viewModel.selectedOption == null 
                    ? null 
                    : () => viewModel.nextQuestion(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    viewModel.isLastQuestion ? 'Submit' : 'Next',
                    style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/quiz_view_model.dart';

class QuizResultScreen extends StatelessWidget {
  final QuizViewModel viewModel;
  final VoidCallback onBackToSkills;

  const QuizResultScreen({
    super.key,
    required this.viewModel,
    required this.onBackToSkills,
  });

  @override
  Widget build(BuildContext context) {
    // 70% passing score
    final percentage = (viewModel.score / viewModel.totalQuestions) * 100;
    final isPassed = percentage >= 70;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPassed ? Icons.check_circle : Icons.cancel,
                  size: 80,
                  color: isPassed ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isPassed ? 'Skill Verified!' : 'Verification Failed',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                isPassed
                    ? 'Congratulations! You have successfully verified your skill: ${viewModel.currentSkill?.skillName}.'
                    : 'You scored ${percentage.toInt()}%. You need 70% to verify this skill.',
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Score: ${viewModel.score} / ${viewModel.totalQuestions}',
                style: AppTextStyles.h3.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onBackToSkills,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back to Skills',
                    style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                  ),
                ),
              ),
              if (!isPassed) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to retry
                    viewModel.retryQuiz();
                  },
                  child: Text(
                    'Try Again',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

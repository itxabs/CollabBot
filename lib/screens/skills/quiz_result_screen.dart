import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/quiz_view_model.dart';

class QuizResultScreen extends StatefulWidget {
  final QuizViewModel viewModel;
  final VoidCallback onBackToSkills;
  final VoidCallback onTryAgain;

  const QuizResultScreen({
    super.key,
    required this.viewModel,
    required this.onBackToSkills,
    required this.onTryAgain,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _toastShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_toastShown) return;
    _toastShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.celebration_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '+${widget.viewModel.totalPointsAwarded} Points Earned - '
                    'Quiz Completed Successfully',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final percentage = widget.viewModel.totalQuestions > 0
        ? (widget.viewModel.score / widget.viewModel.totalQuestions) * 100
        : 0;
    final isPassed = percentage >= QuizViewModel.verificationPassPercentage;

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
                    ? 'Congratulations! You have successfully verified your skill: ${widget.viewModel.currentSkill?.skillName}.'
                    : 'You scored ${percentage.toInt()}%. You need '
                        '${QuizViewModel.verificationPassPercentage}% to verify this skill.',
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Score: ${widget.viewModel.score} / ${widget.viewModel.totalQuestions}',
                style: AppTextStyles.h3.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'Quiz points: +${widget.viewModel.pointsAwarded}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.tealAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.viewModel.verifiedSkillPointsAwarded > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'Verified skill bonus: +${widget.viewModel.verifiedSkillPointsAwarded}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onBackToSkills,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back to Skills',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (!isPassed) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: widget.onTryAgain,
                  child: Text(
                    'Try Again',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

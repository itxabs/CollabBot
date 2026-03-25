import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/questions/questions_view_model.dart';
import '../../data/models/question_model.dart';
import 'question_detail_screen.dart';

class QuestionsScreen extends StatelessWidget {
  const QuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Questions Feed', style: AppTextStyles.h3),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: const _QuestionsContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/ask_question'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _QuestionsContent extends StatelessWidget {
  const _QuestionsContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<QuestionsViewModel>(context);

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No questions yet.', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            Text('Be the first to ask!', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.questions.length,
      itemBuilder: (context, index) {
        final question = viewModel.questions[index];
        return _buildQuestionCard(context, question);
      },
    );
  }

  Widget _buildQuestionCard(BuildContext context, QuestionModel question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuestionDetailScreen(question: question),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(question.authorName[0], style: const TextStyle(fontSize: 10)),
                ),
                const SizedBox(width: 8),
                Text(question.authorName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(question.formattedDate, style: AppTextStyles.bodyMedium.copyWith(fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),
            Text(question.title, style: AppTextStyles.h3.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              question.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStat(Icons.thumb_up_alt_outlined, question.score.toString()),
                const SizedBox(width: 16),
                _buildStat(Icons.mode_comment_outlined, question.answerCount.toString()),
                const SizedBox(width: 16),
                _buildStat(Icons.remove_red_eye_outlined, question.viewCount.toString()),
                const Spacer(),
                if (question.tags.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: question.tags.take(2).map((tag) => _buildTag(tag)).toList(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

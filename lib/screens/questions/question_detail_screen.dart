import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/questions/questions_view_model.dart';
import '../../data/models/question_model.dart';
import '../../widgets/user_role_icon.dart';

class QuestionDetailScreen extends StatefulWidget {
  final QuestionModel question;

  const QuestionDetailScreen({super.key, required this.question});

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  final _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAnswers();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadAnswers() async {
    final viewModel = Provider.of<QuestionsViewModel>(context, listen: false);
    await viewModel.fetchAnswers(widget.question.id);
  }

  void _submitAnswer() async {
    if (_answerController.text.trim().isEmpty) return;

    final viewModel = Provider.of<QuestionsViewModel>(context, listen: false);
    final content = _answerController.text.trim();
    _answerController.clear();

    FocusScope.of(context).unfocus();
    
    try {
      await viewModel.postAnswer(widget.question.id, content);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Answer posted!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Question'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _QuestionHeader(question: widget.question),
                  _buildAnswerStats(),
                  _buildAnswersSection(),
                ],
              ),
            ),
          ),
          _buildAnswerInput(),
        ],
      ),
    );
  }

  Widget _buildAnswerStats() {
    final viewModel = Provider.of<QuestionsViewModel>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.format_list_numbered,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            '${viewModel.answers.length} Answers',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${widget.question.viewCount} views',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswersSection() {
    final viewModel = Provider.of<QuestionsViewModel>(context);

    if (viewModel.isLoadingAnswers) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (viewModel.answers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 60,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No answers yet',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text('Be the first to answer!', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: viewModel.answers.length,
      itemBuilder: (context, index) => _AnswerCard(
        answer: viewModel.answers[index],
        questionId: widget.question.id,
        isFirst: index == 0,
        questionAuthorId: widget.question.authorId,
      ),
    );
  }

  Widget _buildAnswerInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _answerController,
                maxLines: null,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Write your answer...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _submitAnswer,
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionHeader extends StatelessWidget {
  final QuestionModel question;

  const _QuestionHeader({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  question.title,
                  style: AppTextStyles.h2.copyWith(fontSize: 22, height: 1.3),
                ),
              ),
              const SizedBox(width: 16),
              _ThumbsVotingColumn(
                id: question.id,
                score: question.score,
                isQuestion: true,
                authorId: question.authorId,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text(
                  question.authorName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            question.authorName,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if ((question.authorRole ?? '').trim().isNotEmpty) ...[
                          const SizedBox(width: 4),
                          UserRoleIcon(role: question.authorRole),
                        ],
                      ],
                    ),
                    Text(
                      'asked ${_formatTimeAgo(question.createdAt)}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              question.content,
              style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
          if (question.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: question.tags.map((tag) => _buildTag(tag)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class _AnswerCard extends StatelessWidget {
  final AnswerModel answer;
  final String questionId;
  final bool isFirst;
  final String questionAuthorId;

  const _AnswerCard({
    required this.answer,
    required this.questionId,
    this.isFirst = false,
    required this.questionAuthorId,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<QuestionsViewModel>(context, listen: false);
    final isOwnAnswer = viewModel.currentUserId == answer.authorId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
          left: isFirst && answer.isAccepted
              ? const BorderSide(color: AppColors.success, width: 3)
              : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ThumbsVotingColumn(
              id: answer.id,
              score: answer.score,
              isQuestion: false,
              questionId: questionId,
              isAccepted: answer.isAccepted,
              authorId: answer.authorId,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (answer.isAccepted)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Accepted Answer',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.secondary,
                        child: Text(
                          answer.authorName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    answer.authorName,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if ((answer.authorRole ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  UserRoleIcon(role: answer.authorRole),
                                ],
                              ],
                            ),
                            Text(
                              'answered ${_formatTimeAgo(answer.createdAt)}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (isOwnAnswer) ...[
                        _buildEditButton(context, viewModel),
                        const SizedBox(width: 4),
                        _buildDeleteButton(context, viewModel),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      answer.content,
                      style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context, QuestionsViewModel viewModel) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showEditDialog(context, viewModel),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.edit_outlined,
            size: 16,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(
    BuildContext context,
    QuestionsViewModel viewModel,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDeleteDialog(context, viewModel),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.delete_outline,
            size: 16,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, QuestionsViewModel viewModel) {
    final controller = TextEditingController(text: answer.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Answer'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Your answer...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final updatedContent = controller.text.trim();
                Navigator.pop(ctx);
                try {
                  await viewModel.updateAnswer(
                    answer.id,
                    questionId,
                    updatedContent,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating answer: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, QuestionsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Answer'),
        content: const Text('Are you sure you want to delete this answer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await viewModel.deleteAnswer(answer.id, questionId);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class _ThumbsVotingColumn extends StatelessWidget {
  final String id;
  final int score;
  final bool isQuestion;
  final String? questionId;
  final bool isAccepted;
  final String authorId;

  const _ThumbsVotingColumn({
    required this.id,
    required this.score,
    required this.isQuestion,
    this.questionId,
    this.isAccepted = false,
    required this.authorId,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<QuestionsViewModel>(context, listen: false);

    return Column(
      children: [
        _ThumbsButton(
          icon: Icons.thumb_up_outlined,
          onTap: () async {
            final success = await viewModel.vote(
              id,
              isQuestion,
              1,
              questionId: questionId,
              authorId: authorId,
            );
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("You can't vote on your own posts"),
                  backgroundColor: AppColors.warning,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          isActive: score > 0,
          activeColor: AppColors.success,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: score > 0
                ? AppColors.success.withValues(alpha: 0.1)
                : score < 0
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            score > 0 ? '+$score' : score.toString(),
            style: TextStyle(
              color: score > 0
                  ? AppColors.success
                  : score < 0
                  ? AppColors.error
                  : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 4),
        _ThumbsButton(
          icon: Icons.thumb_down_outlined,
          onTap: () async {
            final success = await viewModel.vote(
              id,
              isQuestion,
              -1,
              questionId: questionId,
              authorId: authorId,
            );
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("You can't vote on your own posts"),
                  backgroundColor: AppColors.warning,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          isActive: score < 0,
          activeColor: AppColors.error,
        ),
        if (!isQuestion && isAccepted)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Icon(Icons.check_circle, color: AppColors.success, size: 28),
          ),
      ],
    );
  }
}

class _ThumbsButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;

  const _ThumbsButton({
    required this.icon,
    required this.onTap,
    required this.isActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? activeColor : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isActive ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

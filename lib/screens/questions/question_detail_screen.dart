import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../view_model/questions/questions_view_model.dart';
import '../../data/models/question_model.dart';

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

  Future<void> _loadAnswers() async {
    final viewModel = Provider.of<QuestionsViewModel>(context, listen: false);
    await viewModel.fetchAnswers(widget.question.id);
  }

  void _submitAnswer() async {
    if (_answerController.text.isEmpty) return;
    
    final viewModel = Provider.of<QuestionsViewModel>(context, listen: false);
    final content = _answerController.text;
    _answerController.clear();
    FocusScope.of(context).unfocus();

    try {
      await viewModel.postAnswer(widget.question.id, content);
      await _loadAnswers(); // Refresh
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: const Text('Question', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildQuestionSection(),
            const Divider(height: 1),
            _buildAnswersSection(),
          ],
        ),
      ),
      bottomSheet: _buildAnswerInput(),
    );
  }

  Widget _buildQuestionSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(widget.question.authorName[0], style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Text(widget.question.authorName, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              _buildVoteControl(widget.question.score.toString(), true, widget.question.id),
            ],
          ),
          const SizedBox(height: 16),
          Text(widget.question.title, style: AppTextStyles.h2.copyWith(fontSize: 22)),
          const SizedBox(height: 12),
          Text(widget.question.content, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary, height: 1.5)),
          const SizedBox(height: 20),
          if (widget.question.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.question.tags.map((tag) => _buildTag(tag)).toList(),
            ),
          const SizedBox(height: 16),
          Text(widget.question.formattedDate, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAnswersSection() {
    final viewModel = Provider.of<QuestionsViewModel>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('Answers', style: AppTextStyles.h3),
        ),
        if (viewModel.isLoadingAnswers)
          const Center(child: CircularProgressIndicator())
        else if (viewModel.answers.isEmpty)
           const Padding(
             padding: EdgeInsets.symmetric(horizontal: 20.0),
             child: Text('No answers yet. Share your knowledge!'),
           )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: viewModel.answers.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) => _buildAnswerItem(viewModel.answers[index]),
          ),
        const SizedBox(height: 100), // Space for bottom sheet
      ],
    );
  }

  Widget _buildAnswerItem(AnswerModel answer) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey[200],
                child: Text(answer.authorName[0], style: const TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 8),
              Text(answer.authorName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (answer.isAccepted)
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(answer.content, style: AppTextStyles.bodyLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(answer.formattedDate, style: AppTextStyles.bodyMedium.copyWith(fontSize: 10)),
              const Spacer(),
              _buildVoteControl(answer.score.toString(), false, answer.id, questionId: widget.question.id),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoteControl(String score, bool isQuestion, String id, {String? questionId}) {
    final viewModel = Provider.of<QuestionsViewModel>(context, listen: false);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => viewModel.vote(id, isQuestion, 1, questionId: questionId), 
          icon: const Icon(Icons.arrow_upward, size: 20),
          visualDensity: VisualDensity.compact,
        ),
        Text(score, style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: () => viewModel.vote(id, isQuestion, -1, questionId: questionId),
          icon: const Icon(Icons.arrow_downward, size: 20),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildAnswerInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                hintText: 'Write your answer...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _submitAnswer(),
            icon: const Icon(Icons.send, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

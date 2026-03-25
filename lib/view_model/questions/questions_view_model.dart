import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/question_model.dart';
import '../../data/services/question_service.dart';

class QuestionsViewModel extends ChangeNotifier {
  final QuestionService _service = QuestionService();
  final SupabaseClient _client = Supabase.instance.client;

  List<QuestionModel> _questions = [];
  List<AnswerModel> _answers = [];
  bool _isLoading = false;
  bool _isLoadingAnswers = false;

  List<QuestionModel> get questions => _questions;
  List<AnswerModel> get answers => _answers;
  bool get isLoading => _isLoading;
  bool get isLoadingAnswers => _isLoadingAnswers;

  QuestionsViewModel() {
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _questions = await _service.getQuestions();
    } catch (e) {
      print('Fetch Questions Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAnswers(String questionId) async {
    _isLoadingAnswers = true;
    notifyListeners();
    try {
      await _service.incrementViewCount(questionId);
      _answers = await _service.getAnswers(questionId);
    } catch (e) {
      print('Fetch Answers Error: $e');
    } finally {
      _isLoadingAnswers = false;
      notifyListeners();
    }
  }

  Future<void> askQuestion(String title, String content, List<String> tags) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      await _service.createQuestion(user.id, title, content, tags);
      await fetchQuestions();
    }
  }

  Future<void> postAnswer(String questionId, String content) async {
     final user = _client.auth.currentUser;
    if (user != null) {
      await _service.postAnswer(questionId, user.id, content);
      await fetchQuestions(); // Updates comment counts in feed
    }
  }

  Future<void> vote(String targetId, bool isQuestion, int voteValue, {String? questionId}) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      await _service.vote(targetId, user.id, isQuestion, voteValue);
      if (isQuestion) {
        await fetchQuestions();
      } else if (questionId != null) {
        await fetchAnswers(questionId);
      }
      notifyListeners();
    }
  }
}

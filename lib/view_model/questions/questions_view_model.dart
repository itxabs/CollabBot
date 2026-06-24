import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/question_model.dart';
import '../../data/repositories/question_repository.dart';
import '../../data/services/question_service.dart';

enum QuestionFilter { newest, mostVotes, mostViewed, unanswered }

class QuestionsViewModel extends ChangeNotifier {
  final QuestionRepository _repository = QuestionRepository(QuestionService());
  final SupabaseClient _client = Supabase.instance.client;

  List<QuestionModel> _questions = [];
  List<AnswerModel> _answers = [];
  bool _isLoading = false;
  bool _isLoadingAnswers = false;
  QuestionFilter _currentFilter = QuestionFilter.newest;
  String _searchQuery = '';

  List<QuestionModel> get questions {
    List<QuestionModel> filtered = List.from(_questions);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((q) {
        return q.title.toLowerCase().contains(query) ||
            q.content.toLowerCase().contains(query) ||
            q.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    switch (_currentFilter) {
      case QuestionFilter.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case QuestionFilter.mostVotes:
        filtered.sort((a, b) => b.score.compareTo(a.score));
        break;
      case QuestionFilter.mostViewed:
        filtered.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case QuestionFilter.unanswered:
        filtered = filtered.where((q) => q.answerCount == 0).toList();
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  List<QuestionModel> get allQuestions => _questions;
  List<AnswerModel> get answers => _answers;
  bool get isLoading => _isLoading;
  bool get isLoadingAnswers => _isLoadingAnswers;
  QuestionFilter get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;

  String? get currentUserId => _client.auth.currentUser?.id;

  QuestionsViewModel() {
    fetchQuestions();
  }

  void setFilter(QuestionFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchQuestions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _questions = await _repository.getQuestions();
    } catch (e) {
      debugPrint('Fetch Questions Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAnswers(String questionId) async {
    _isLoadingAnswers = true;
    notifyListeners();
    try {
      await _repository.incrementViewCount(questionId);
      _answers = await _repository.getAnswers(questionId);
    } catch (e) {
      debugPrint('Fetch Answers Error: $e');
    } finally {
      _isLoadingAnswers = false;
      notifyListeners();
    }
  }

  Future<void> askQuestion(
    String title,
    String content,
    List<String> tags,
  ) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      await _repository.createQuestion(user.id, title, content, tags);
      await fetchQuestions();
    }
  }

  Future<void> postAnswer(String questionId, String content) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      await _repository.postAnswer(questionId, user.id, content);
      await fetchAnswers(questionId);
      await fetchQuestions();
    }
  }

  Future<void> deleteAnswer(String answerId, String questionId) async {
    await _repository.deleteAnswer(answerId);
    await fetchAnswers(questionId);
    await fetchQuestions();
  }

  Future<void> updateAnswer(
    String answerId,
    String questionId,
    String content,
  ) async {
    await _repository.updateAnswer(answerId, content);
    await fetchAnswers(questionId);
  }

  Future<bool> vote(
    String targetId,
    bool isQuestion,
    int voteValue, {
    String? questionId,
    required String authorId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    if (authorId == user.id) {
      return false;
    }

    await _repository.vote(targetId, user.id, isQuestion, voteValue);
    if (isQuestion) {
      await fetchQuestions();
    } else if (questionId != null) {
      await fetchAnswers(questionId);
    }
    notifyListeners();
    return true;
  }
}

import '../models/question_model.dart';
import '../services/question_service.dart';

class QuestionRepository {
  final QuestionService _service;

  QuestionRepository(this._service);

  Future<List<QuestionModel>> getQuestions() async {
    return await _service.getQuestions();
  }

  Future<void> incrementViewCount(String questionId) async {
    await _service.incrementViewCount(questionId);
  }

  Future<List<AnswerModel>> getAnswers(String questionId) async {
    return await _service.getAnswers(questionId);
  }

  Future<void> createQuestion(
    String authorId,
    String title,
    String content,
    List<String> tags,
  ) async {
    await _service.createQuestion(authorId, title, content, tags);
  }

  Future<void> postAnswer(
    String questionId,
    String authorId,
    String content,
  ) async {
    await _service.postAnswer(questionId, authorId, content);
  }

  Future<void> vote(
    String targetId,
    String userId,
    bool isQuestion,
    int voteValue,
  ) async {
    await _service.vote(targetId, userId, isQuestion, voteValue);
  }

  Future<void> deleteAnswer(String answerId) async {
    await _service.deleteAnswer(answerId);
  }

  Future<void> updateAnswer(String answerId, String content) async {
    await _service.updateAnswer(answerId, content);
  }
}

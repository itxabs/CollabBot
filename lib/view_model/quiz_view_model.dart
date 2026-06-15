import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/profile_models.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/services/gemini_service.dart';

class QuizViewModel extends ChangeNotifier {
  static const int verificationPassPercentage = 80;
  static const int verifiedSkillPoints = 15;

  final GeminiService _geminiService;
  final ProfileRepository _profileRepository;

  // State
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  String? _selectedOption;
  int _score = 0;
  bool _isSubmitted = false;
  int _pointsAwarded = 0;
  int _verifiedSkillPointsAwarded = 0;
  bool _rewardLogged = false;

  // Skill context
  UserSkill? _currentSkill;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  String? get selectedOption => _selectedOption;
  int get score => _score;
  bool get isSubmitted => _isSubmitted;
  UserSkill? get currentSkill => _currentSkill;
  int get scorePercentage =>
      totalQuestions > 0 ? ((_score / totalQuestions) * 100).round() : 0;
  int get scoreBonus => _scoreBonusForPercentage(scorePercentage);
  int get pointsAwarded => _pointsAwarded;
  int get verifiedSkillPointsAwarded => _verifiedSkillPointsAwarded;
  int get totalPointsAwarded => _pointsAwarded + _verifiedSkillPointsAwarded;

  bool get isLastQuestion => _currentQuestionIndex == _questions.length - 1;
  int get totalQuestions => _questions.length;
  double get progressPercentage =>
      totalQuestions > 0 ? (_currentQuestionIndex + 1) / totalQuestions : 0.0;

  QuizViewModel({
    required GeminiService geminiService,
    required ProfileRepository profileRepository,
  })  : _geminiService = geminiService,
        _profileRepository = profileRepository;

  // Initializer
  Future<void> startQuiz(UserSkill skill) async {
    _currentSkill = skill;
    _questions = [];
    _currentQuestionIndex = 0;
    _score = 0;
    _selectedOption = null;
    _isSubmitted = false;
    _pointsAwarded = 0;
    _verifiedSkillPointsAwarded = 0;
    _rewardLogged = false;
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      _questions = await _geminiService.generateQuiz(skill.skillName);
    } catch (e) {
      _errorMessage =
          'Failed to generate quiz. Please try again later.\nError: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectOption(String option) {
    _selectedOption = option;
    notifyListeners();
  }

  void nextQuestion() {
    if (_selectedOption == null) return;

    // Check answer
    final currentQuestion = _questions[_currentQuestionIndex];
    if (currentQuestion['correctAnswer'] == _selectedOption) {
      _score++;
    }

    if (!isLastQuestion) {
      _currentQuestionIndex++;
      _selectedOption = null;
    } else {
      submitQuiz();
    }
    notifyListeners();
  }

  Future<void> submitQuiz() async {
    _isSubmitted = true;
    _isLoading = true;
    notifyListeners();

    try {
      final percentage = scorePercentage;
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      if (percentage >= verificationPassPercentage &&
          _currentSkill != null &&
          !_currentSkill!.isVerified) {
        await _profileRepository.verifySkill(_currentSkill!.id);

        if (currentUserId != null) {
          _verifiedSkillPointsAwarded = verifiedSkillPoints;
          await _profileRepository.addLeaderboardPoints(
            currentUserId,
            verifiedSkillPoints,
            'verified_skill',
          );
        }
      }

      if (!_rewardLogged && currentUserId != null) {
        _pointsAwarded = 5 + scoreBonus;
        await _profileRepository.addLeaderboardPoints(
          currentUserId,
          _pointsAwarded,
          'quiz_attempt',
        );
        _rewardLogged = true;
      }
    } catch (e) {
      _errorMessage = 'Error submitting result: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void retryQuiz() {
    if (_currentSkill != null) {
      startQuiz(_currentSkill!);
    }
  }

  int _scoreBonusForPercentage(int percentage) {
    if (percentage >= 80) return 80;
    if (percentage >= 60) return 50;
    if (percentage >= 40) return 20;
    return 0;
  }
}

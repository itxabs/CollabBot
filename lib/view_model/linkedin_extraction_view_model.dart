import 'package:collab_bot/core/services/linkedin_extraction_service.dart';
import 'package:flutter/material.dart';

/// ViewModel for LinkedIn Profile Extraction
/// 
/// Manages state for:
/// - HTML extraction
/// - Image extraction (OCR)
/// - Resume analysis
/// - Loading states and errors
/// 
/// Used with Provider pattern for state management

class LinkedInExtractionViewModel extends ChangeNotifier {
  // Loading states
  bool _isLoadingHtml = false;
  bool _isLoadingImage = false;
  bool _isLoadingResume = false;
  bool _isCheckingHealth = false;

  // Data
  List<String> _extractedSkills = [];
  List<Map<String, String>> _extractedExperience = [];
  int _resumeScore = 0;
  List<String> _resumeRecommendations = [];
  
  // Service status
  Map<String, dynamic> _healthStatus = {};

  // Error handling
  String? _errorMessage;
  bool _hasError = false;

  // Getters
  bool get isLoadingHtml => _isLoadingHtml;
  bool get isLoadingImage => _isLoadingImage;
  bool get isLoadingResume => _isLoadingResume;
  bool get isCheckingHealth => _isCheckingHealth;

  List<String> get extractedSkills => _extractedSkills;
  List<Map<String, String>> get extractedExperience => _extractedExperience;
  int get resumeScore => _resumeScore;
  List<String> get resumeRecommendations => _resumeRecommendations;
  
  Map<String, dynamic> get healthStatus => _healthStatus;
  
  String? get errorMessage => _errorMessage;
  bool get hasError => _hasError;

  // Clear error
  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all extracted data
  void clearData() {
    _extractedSkills = [];
    _extractedExperience = [];
    _resumeScore = 0;
    _resumeRecommendations = [];
    _errorMessage = null;
    _hasError = false;
    notifyListeners();
  }

  /// Extract LinkedIn data from HTML
  /// 
  /// Args:
  ///   html: Raw HTML from LinkedIn profile
  Future<bool> extractFromHtml(String html) async {
    _isLoadingHtml = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      if (html.trim().isEmpty) {
        throw Exception('HTML content cannot be empty');
      }

      final result = await LinkedInExtractionService.extractFromHtml(html);

      if (result['success'] != false) {
        _extractedSkills = List<String>.from(result['skills'] ?? []);
        _extractedExperience = LinkedInExtractionService.parseExperience(
          result['experience'] ?? [],
        );
        _isLoadingHtml = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(result['error'] ?? 'Unknown error during extraction');
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'HTML Extraction Error: ${e.toString()}';
      _isLoadingHtml = false;
      notifyListeners();
      return false;
    }
  }

  /// Extract LinkedIn data from image screenshot
  /// 
  /// Args:
  ///   imagePath: Path to LinkedIn screenshot
  Future<bool> extractFromImage(String imagePath) async {
    _isLoadingImage = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      if (imagePath.trim().isEmpty) {
        throw Exception('Image path cannot be empty');
      }

      final result = await LinkedInExtractionService.extractFromImage(imagePath);

      if (result['success'] != false) {
        _extractedSkills = List<String>.from(result['skills'] ?? []);
        _extractedExperience = LinkedInExtractionService.parseExperience(
          result['experience'] ?? [],
        );
        _isLoadingImage = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(result['error'] ?? 'Unknown error during extraction');
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Image Extraction Error: ${e.toString()}';
      _isLoadingImage = false;
      notifyListeners();
      return false;
    }
  }

  /// Analyze resume file
  /// 
  /// Args:
  ///   filePath: Path to resume (PDF or DOCX)
  ///   userId: User ID for storing resume
  Future<bool> analyzeResume(String filePath, String userId) async {
    _isLoadingResume = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      if (filePath.trim().isEmpty) {
        throw Exception('File path cannot be empty');
      }

      if (userId.trim().isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      final result = await LinkedInExtractionService.analyzeResume(
        filePath,
        userId,
      );

      if (result['success'] != false) {
        _resumeScore = result['score'] ?? 0;
        _resumeRecommendations =
            List<String>.from(result['recommendations'] ?? []);
        _isLoadingResume = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(result['error'] ?? 'Unknown error during analysis');
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Resume Analysis Error: ${e.toString()}';
      _isLoadingResume = false;
      notifyListeners();
      return false;
    }
  }

  /// Check health of all backend services
  Future<bool> checkBackendHealth() async {
    _isCheckingHealth = true;
    notifyListeners();

    try {
      _healthStatus = await LinkedInExtractionService.checkHealth();
      _isCheckingHealth = false;
      notifyListeners();
      return _healthStatus['status'] == 'operational';
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Health Check Error: ${e.toString()}';
      _isCheckingHealth = false;
      notifyListeners();
      return false;
    }
  }

  /// Add manual skill
  void addSkill(String skill) {
    if (skill.trim().isNotEmpty && !_extractedSkills.contains(skill)) {
      _extractedSkills.add(skill);
      notifyListeners();
    }
  }

  /// Remove skill
  void removeSkill(String skill) {
    _extractedSkills.remove(skill);
    notifyListeners();
  }

  /// Add manual experience
  void addExperience(String roleCompany, String duration) {
    if (roleCompany.trim().isNotEmpty) {
      _extractedExperience.add({
        'roleCompany': roleCompany,
        'duration': duration,
      });
      notifyListeners();
    }
  }

  /// Remove experience by index
  void removeExperience(int index) {
    if (index >= 0 && index < _extractedExperience.length) {
      _extractedExperience.removeAt(index);
      notifyListeners();
    }
  }
}

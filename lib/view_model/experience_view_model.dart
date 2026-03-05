import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/profile_models.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/profile_service.dart';

class ExperienceViewModel extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  // State
  List<Experience> _experiences = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Experience> get experiences => _experiences;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ExperienceViewModel()
      : _profileRepository = ProfileRepositoryImpl(
          ProfileService(Supabase.instance.client),
        );

  // Load experiences
  Future<void> loadExperiences() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _experiences = await _profileRepository.getUserExperiences(currentUser.id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new experience
  Future<void> addExperience(
    BuildContext context, {
    required String organization,
    required String title,
    String? description,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.addExperience(
        userId: currentUser.id,
        organization: organization,
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
      );

      // Refresh list
      await loadExperiences();

      if (context.mounted) {
        Navigator.pop(context); // Go back to list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Experience added successfully')),
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

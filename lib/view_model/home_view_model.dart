import 'package:flutter/material.dart';

class Mentor {
  final String name;
  final String role;
  final String company;
  final String imageUrl;

  Mentor({required this.name, required this.role, required this.company, required this.imageUrl});
}

class HomeViewModel extends ChangeNotifier {
  int _points = 1250;
  int get points => _points;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Mentor> _suggestedMentors = [];
  List<Mentor> get suggestedMentors => _suggestedMentors;

  HomeViewModel() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    // Simulate API fetch
    await Future.delayed(const Duration(seconds: 1));
    
    _suggestedMentors = [
      Mentor(name: 'Sarah Chen', role: 'Product Designer', company: 'Google', imageUrl: ''),
      Mentor(name: 'Alex Morgan', role: 'Flutter Expert', company: 'Freelance', imageUrl: ''),
      Mentor(name: 'David Kim', role: 'Senior Engineer', company: 'Amazon', imageUrl: ''),
    ];

    _isLoading = false;
    notifyListeners();
  }
}

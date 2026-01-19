import 'package:flutter/material.dart';
import '../core/constants/routes.dart';

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon; // Using IconData for now as per design analysis
  final Color color;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class OnboardingViewModel extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  final PageController pageController = PageController();

  final List<OnboardingItem> items = [
    OnboardingItem(
      title: 'Connect with Mentors',
      description: 'Find experienced mentors who can guide you through your journey.',
      icon: Icons.people_outline,
      color: Color(0xFF5046E5), // Indigo
    ),
    OnboardingItem(
      title: 'AI-Powered Matching',
      description: 'Get matched with the perfect study partners using our AI algorithms.',
      icon: Icons.auto_awesome, 
      color: Color(0xFFFF6F3D), // Orange
    ),
    OnboardingItem(
      title: 'Real-time Collaboration',
      description: 'Collaborate on projects and learn together in real-time.',
      icon: Icons.sync,
      color: Color(0xFF10B981), // Green
    ),
    OnboardingItem(
      title: 'Earn Recognition',
      description: 'Showcase your skills and earn badges for your achievements.',
      icon: Icons.emoji_events_outlined,
      color: Color(0xFFFFD700), // Gold (Approx)
    ),
  ];

  void onPageChanged(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void nextPage(BuildContext context) {
    if (_currentIndex < items.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding(context);
    }
  }

  void skip(BuildContext context) {
    _finishOnboarding(context);
  }

  void _finishOnboarding(BuildContext context) {
    // Navigate to Login/Auth
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
}

import 'package:flutter/material.dart';

class Event {
  final String title;
  final String date;
  final String location;
  final String imageUrl;
  final bool isSaved;

  Event({
    required this.title,
    required this.date,
    required this.location,
    required this.imageUrl,
    this.isSaved = false,
  });
}

class EventsViewModel extends ChangeNotifier {
  List<Event> _upcomingEvents = [];
  List<Event> get upcomingEvents => _upcomingEvents;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  EventsViewModel() {
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _upcomingEvents = [
      Event(title: 'Flutter Forward 2026', date: 'Jan 25, 2026', location: 'Virtual', imageUrl: ''),
      Event(title: 'Dart Meetup', date: 'Feb 10, 2026', location: 'San Francisco', imageUrl: ''),
      Event(title: 'AI in Design', date: 'Feb 15, 2026', location: 'London', imageUrl: ''),
    ];

    _isLoading = false;
    notifyListeners();
  }
}

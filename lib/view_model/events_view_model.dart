import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/event_model.dart';

class EventsViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<EventModel> _upcomingEvents = [];
  List<EventModel> get upcomingEvents => _upcomingEvents;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  EventsViewModel() {
    loadEvents();
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('events')
          .select('*, users(full_name)')
          .order('event_date', ascending: true);
      
      _upcomingEvents = (response as List)
          .map((json) => EventModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading events: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createEvent(EventModel event) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('events').insert(event.toJson());
      await loadEvents(); // Refresh list
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error creating event: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}


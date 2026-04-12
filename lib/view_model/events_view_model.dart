import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/event_model.dart';

class EventsViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<EventModel> _allEvents = [];
  List<EventModel> _savedEvents = [];
  List<EventModel> _myEvents = [];
  
  String _searchQuery = '';
  String _currentTab = 'Upcoming';
  bool _isLoading = false;

  List<EventModel> get filteredEvents {
    List<EventModel> baseList;
    if (_currentTab == 'Saved') {
      baseList = _savedEvents;
    } else if (_currentTab == 'My Events') {
      baseList = _myEvents;
    } else {
      // Upcoming: Only show Approved (status_id = 2)
      // AND Date must be present/future
      // AND Vacancy must be available (enrolled < total_seats)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      baseList = _allEvents.where((e) {
        final isApproved = e.status == '2';
        final isNotPast = e.date.isAtSameMomentAs(today) || e.date.isAfter(today);
        final hasVacancy = e.totalSeats == 0 || e.enrolledCount < e.totalSeats;
        
        return isApproved && isNotPast && hasVacancy;
      }).toList();
    }

    if (_searchQuery.isEmpty) return baseList;
    
    return baseList.where((e) => 
      e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      e.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      e.venue.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      e.category.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  bool get isLoading => _isLoading;
  String get currentTab => _currentTab;

  EventsViewModel() {
    loadEvents();
  }

  bool isEventSaved(String? eventId) {
    if (eventId == null) return false;
    return _savedEvents.any((e) => e.eventId == eventId);
  }

  void setTab(String tab) {
    _currentTab = tab;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();

    final userId = _supabase.auth.currentUser?.id;

    try {
      // Load All Events
      final response = await _supabase
          .from('events')
          .select('*, users(full_name)')
          .order('event_date', ascending: true);
      
      _allEvents = (response as List)
          .map((json) => EventModel.fromJson(json))
          .toList();

      // Load My Events (where user is registered)
      if (userId != null) {
        try {
          final registeredResponse = await _supabase
              .from('event_registrations')
              .select('event_id')
              .eq('user_id', userId);
          
          final registeredIds = (registeredResponse as List).map((r) => r['event_id']).toSet();
          _myEvents = _allEvents.where((e) => registeredIds.contains(e.eventId)).toList();
        } catch (e) {
          debugPrint('Error loading registrations: $e');
          _myEvents = [];
        }
      }

      // Load Saved Events (Mocking for now, would need a junction table 'saved_events')
      // For now, let's assume we fetch them if such a table exists
      try {
        final savedResponse = await _supabase
            .from('saved_events')
            .select('event_id')
            .eq('user_id', userId ?? '');
        
        final savedIds = (savedResponse as List).map((s) => s['event_id']).toSet();
        _savedEvents = _allEvents.where((e) => savedIds.contains(e.eventId)).toList();
      } catch (e) {
        debugPrint('Saved events table might not exist: $e');
        _savedEvents = [];
      }

    } catch (e) {
      debugPrint('Error loading events: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> createEvent(EventModel event) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('events').insert(event.toJson());
      await loadEvents(); // Refresh list
      return null; // Success
    } catch (e) {
      debugPrint('Error creating event: $e');
      _isLoading = false;
      notifyListeners();
      return e.toString().contains('column "status_id" does not exist') 
          ? "Database error: You must run the SQL setup in Supabase Dashboard!"
          : "Failed to create event: $e";
    }
  }

  Future<String?> registerForEvent(EventModel event) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return "User not logged in";

    // Check if full
    if (event.totalSeats > 0 && event.enrolledCount >= event.totalSeats) {
      return "Registration closed: Full capacity";
    }

    // Check if date passed
    if (event.date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return "Registration closed: Event date has passed";
    }

    try {
      // 1. Insert into event_registrations
      if (event.eventId == null) return "Invalid event ID";
      
      await _supabase.from('event_registrations').insert({
        'event_id': event.eventId!,
        'user_id': userId,
        'registered_at': DateTime.now().toIso8601String(),
      });

      // 2. Increment enrolled_count in events table
      await _supabase.rpc('increment_enrolled_count', params: {'row_id': event.eventId!});

      await loadEvents();
      return null; // Success
    } catch (e) {
      debugPrint('Error registering: $e');
      return "Registration failed. You might already be enrolled.";
    }
  }

  Future<void> toggleSaveEvent(EventModel event) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    if (event.eventId == null) return;
    final isSaved = _savedEvents.any((e) => e.eventId == event.eventId);

    try {
      if (isSaved) {
        await _supabase.from('saved_events').delete().match({'user_id': userId, 'event_id': event.eventId!});
      } else {
        await _supabase.from('saved_events').insert({'user_id': userId, 'event_id': event.eventId!});
      }
      await loadEvents();
    } catch (e) {
      debugPrint('Error saving event: $e');
    }
  }
}


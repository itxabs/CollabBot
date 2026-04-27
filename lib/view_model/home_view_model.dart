import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/user_repository.dart';

class Mentor {
  final String name;
  final String role;
  final String company;
  final String imageUrl;

  Mentor({
    required this.name,
    required this.role,
    required this.company,
    required this.imageUrl,
  });
}

class HomeEventPreview {
  final String title;
  final String dateTimeLabel;
  final int attendingCount;

  HomeEventPreview({
    required this.title,
    required this.dateTimeLabel,
    required this.attendingCount,
  });
}

class HomeViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserRepository _userRepository = UserRepository();
  final String? currentUserId;

  int _points = 0;
  int get points => _points;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Mentor> _suggestedMentors = [];
  List<Mentor> get suggestedMentors => _suggestedMentors;

  List<HomeEventPreview> _upcomingEvents = [];
  List<HomeEventPreview> get upcomingEvents => _upcomingEvents;

  HomeViewModel({this.currentUserId}) {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    // Keep existing mentor mock data for now.
    _suggestedMentors = [
      Mentor(
        name: 'Sarah Chen',
        role: 'Product Designer',
        company: 'Google',
        imageUrl: '',
      ),
      Mentor(
        name: 'Alex Morgan',
        role: 'Flutter Expert',
        company: 'Freelance',
        imageUrl: '',
      ),
      Mentor(
        name: 'David Kim',
        role: 'Senior Engineer',
        company: 'Amazon',
        imageUrl: '',
      ),
    ];

    await _loadUserReputation();
    await _loadUpcomingEventsFromDb();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserReputation() async {
    final userId = currentUserId ?? _supabase.auth.currentUser?.id;
    if (userId == null) {
      _points = 0;
      return;
    }

    try {
      final user = await _userRepository.getUserById(userId);
      _points = user?.reputation ?? 0;
    } catch (_) {
      _points = 0;
    }
  }

  Future<void> _loadUpcomingEventsFromDb() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final response = await _supabase
          .from('events')
          .select(
            'id, creator_id, title, description, venue, event_date, start_time, end_time, status_id, created_at, deleted_at, total_seats, enrolled_count, image_url',
          )
          .isFilter('deleted_at', null)
          .eq('status_id', 2)
          .gte('event_date', today)
          .order('event_date', ascending: true)
          .limit(8);

      final rows = List<Map<String, dynamic>>.from(response as List);

      _upcomingEvents = rows.map((row) {
        final date =
            DateTime.tryParse(row['event_date']?.toString() ?? '') ??
            DateTime.now();
        final startTime = _parseTimeLabel(row['start_time']?.toString());
        final dateLabel = DateFormat('MMM d').format(date);
        final dateTimeLabel = '$dateLabel - $startTime';

        return HomeEventPreview(
          title: (row['title'] as String?)?.trim().isNotEmpty == true
              ? (row['title'] as String).trim()
              : 'Untitled Event',
          dateTimeLabel: dateTimeLabel,
          attendingCount: _toInt(row['enrolled_count']),
        );
      }).toList();
    } catch (_) {
      _upcomingEvents = [];
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _parseTimeLabel(String? rawTime) {
    if (rawTime == null || rawTime.trim().isEmpty) return 'TBA';
    try {
      final parsed = DateFormat('HH:mm:ss').parse(rawTime);
      return DateFormat('h:mm a').format(parsed);
    } catch (_) {
      try {
        final parsed = DateFormat('HH:mm').parse(rawTime);
        return DateFormat('h:mm a').format(parsed);
      } catch (_) {
        return rawTime;
      }
    }
  }
}

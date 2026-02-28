class EventModel {
  final String? eventId;
  final String title;
  final String? status;
  final DateTime date;
  final String category; // maps to event_type
  final String startTime;
  final String endTime;
  final String venue;
  final String description;
  final String creatorId;
  final String? creatorName;

  EventModel({
    this.eventId,
    required this.title,
    this.status,
    required this.date,
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.venue,
    required this.description,
    required this.creatorId,
    this.creatorName,
  });

  /// JSON → Dart
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      eventId: json['id'] as String?,
      title: json['title'] as String,
      status: json['status_id']?.toString(),
      date: json['event_date'] != null ? DateTime.parse(json['event_date']) : DateTime.now(),
      category: json['category'] ?? (json['event_type'] ?? 'General'),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      venue: json['venue'] ?? '',
      description: json['description'] ?? '',
      creatorId: json['creator_id'] as String,
      creatorName: json['users']?['full_name'] as String?,
    );
  }

  /// Dart → JSON (insert / update)
  Map<String, dynamic> toJson() {
    return {
      if (eventId != null) 'id': eventId,
      'title': title,
      'status_id': status != null ? int.tryParse(status!) ?? 1 : 1, // Default status 1
      'event_date': date.toIso8601String().split('T')[0],
      'category': category,
      'start_time': startTime,
      'end_time': endTime,
      'venue': venue,
      'description': description,
      'creator_id': creatorId,
    };
  }
}


class EventModel {
  final String eventId;
  final String status;
  final DateTime date;
  final String eventType;
  final String startTime;
  final String endTime;
  final String venue;
  final String description;

  EventModel({
    required this.eventId,
    required this.status,
    required this.date,
    required this.eventType,
    required this.startTime,
    required this.endTime,
    required this.venue,
    required this.description,
  });

  /// JSON → Dart
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      eventId: json['event_id'] as String,
      status: json['status'] as String,
      date: DateTime.parse(json['date']),
      eventType: json['event_type'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      venue: json['venue'] as String,
      description: json['description'] as String,
    );
  }

  /// Dart → JSON (insert / update)
  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'status': status,
      'date': date.toIso8601String(),
      'event_type': eventType,
      'start_time': startTime,
      'end_time': endTime,
      'venue': venue,
      'description': description,
    };
  }
}

import 'package:collab_bot/widgets/events/info_row.dart';
import 'package:flutter/material.dart';

class EventCard extends StatelessWidget {
  final String tag;
  final Color tagColor;
  final String title;
  final String description;
  final String date;
  final String time;
  final String location;
  final String attendees;

  const EventCard({
    super.key,
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.attendees,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Banner
          Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              gradient: LinearGradient(
                colors: [tagColor.withOpacity(0.2), tagColor.withOpacity(0.05)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    backgroundColor: tagColor.withOpacity(0.15),
                    label: Text(tag, style: TextStyle(color: tagColor)),
                  ),
                  const Icon(Icons.bookmark_border),
                ],
              ),
            ),
          ),

          /// Content
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16),bottomRight: Radius.circular(16)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),

                  InfoRow(Icons.calendar_today, date),
                  InfoRow(Icons.access_time, time),
                  InfoRow(Icons.location_on, location),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        attendees,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28A745),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text("Register"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

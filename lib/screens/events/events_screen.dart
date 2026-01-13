import 'package:collab_bot/widgets/events/event_card.dart';
import 'package:collab_bot/widgets/events/tab_chips.dart';
import 'package:flutter/material.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  static const Color primaryGreen = Color(0xFF28A745);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Events",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Create"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Search
            TextField(
              decoration: InputDecoration(
                hintText: "Search events...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Tabs
            Row(
              children: const [
                TabChip(label: "Upcoming", selected: true),
                SizedBox(width: 10),
                TabChip(label: "Saved"),
                SizedBox(width: 10),
                TabChip(label: "My Events"),
              ],
            ),

            const SizedBox(height: 20),

            /// Event Cards
            EventCard(
              tag: "Workshop",
              tagColor: primaryGreen,
              title: "Flutter Development Workshop",
              description:
                  "Learn to build beautiful cross-platform apps with Flutter and Dart.",
              date: "Jan 15, 2026",
              time: "3:00 PM - 5:00 PM",
              location: "Room 301, CS Building",
              attendees: "45/60 attending",
            ),

            const SizedBox(height: 16),

            EventCard(
              tag: "Seminar",
              tagColor: Colors.orange,
              title: "AI in Education Seminar",
              description:
                  "Explore how artificial intelligence is transforming education.",
              date: "Jan 18, 2026",
              time: "2:00 PM - 4:00 PM",
              location: "Auditorium Hall",
              attendees: "30/50 attending",
            ),
          ],
        ),
      ),
    );
  }
}

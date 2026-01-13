import 'package:flutter/material.dart';

class EventCard extends StatelessWidget {
  final String title;
  final String date;

  const EventCard({super.key, required this.title, required this.date});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Color(0xFF28A745)),
        title: Text(title),
        subtitle: Text(date),
      ),
    );
  }
}

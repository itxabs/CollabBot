import 'package:flutter/material.dart';

class SuggestionCard extends StatelessWidget {
  final String initials, name, role;
  final List<String> skills;

  const SuggestionCard({super.key, 
    required this.initials,
    required this.name,
    required this.role,
    required this.skills,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF28A745),
          child: Text(initials, style: const TextStyle(color: Colors.white)),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: skills
                  .map(
                    (e) => Chip(
                      backgroundColor: Color(0xFFE8F5EC),
                      side: BorderSide(style: BorderStyle.none),
                      label: Text(e, style: const TextStyle(fontSize: 12, color: Color(0xFF28A745))),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

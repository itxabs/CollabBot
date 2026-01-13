import 'package:flutter/material.dart';

class TabChip extends StatelessWidget {
  final String label;
  final bool selected;

  const TabChip({super.key, 
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor:
          selected ? const Color(0xFF28A745) : Colors.white,
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

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
  final String? imageUrl;
  final bool isSaved;
  final VoidCallback? onRegister;
  final VoidCallback? onSave;

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
    this.imageUrl,
    this.isSaved = false,
    this.onRegister,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      clipBehavior: Clip.antiAlias, // Ensures children don't overflow rounded corners
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Banner
          Stack(
            children: [
              Container(
                height: 150, // Increased height for better visibility
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tagColor.withValues(alpha: 0.2), tagColor.withValues(alpha: 0.05)],
                  ),
                ),
                child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.image, color: tagColor.withValues(alpha: 0.5), size: 50),
                    )
                  : Center(child: Icon(Icons.event_available, color: tagColor.withValues(alpha: 0.3), size: 60)),
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Text(
                        tag, 
                        style: TextStyle(color: tagColor, fontWeight: FontWeight.bold, fontSize: 12)
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border, 
                          color: isSaved ? tagColor : Colors.grey,
                          size: 20,
                        ),
                        onPressed: onSave,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          /// Content
          Container(
            color: Colors.white,
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
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  InfoRow(Icons.calendar_today_outlined, date),
                  const SizedBox(height: 8),
                  InfoRow(Icons.access_time, time),
                  const SizedBox(height: 8),
                  InfoRow(Icons.location_on_outlined, location),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Enrollment', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Text(
                            attendees,
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share_outlined, color: Colors.grey, size: 20),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sharing event...')),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton(
                            onPressed: onRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Register", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
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

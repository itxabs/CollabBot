import 'package:collab_bot/widgets/events/info_row.dart';
import 'package:flutter/material.dart';

class EventCard extends StatefulWidget {
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
  final String eventId;
  final String creatorId;
  final Future<void> Function()? onRegister;
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
    required this.eventId,
    required this.creatorId,
    this.imageUrl,
    this.isSaved = false,
    this.onRegister,
    this.onSave,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isRegistering = false;

  Future<void> _handleRegister() async {
    if (widget.onRegister == null || _isRegistering) return;
    setState(() => _isRegistering = true);
    try {
      await widget.onRegister!();
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Banner Image
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.tagColor.withValues(alpha: 0.2),
                      widget.tagColor.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: _buildBannerImage(),
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Category tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Text(
                        widget.tag,
                        style: TextStyle(
                          color: widget.tagColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // Bookmark button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: IconButton(
                        icon: Icon(
                          widget.isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: widget.isSaved ? widget.tagColor : Colors.grey,
                          size: 20,
                        ),
                        onPressed: widget.onSave,
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
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  InfoRow(Icons.calendar_today_outlined, widget.date),
                  const SizedBox(height: 8),
                  InfoRow(Icons.access_time, widget.time),
                  const SizedBox(height: 8),
                  InfoRow(Icons.location_on_outlined, widget.location),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Enrollment',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          Text(
                            widget.attendees,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      // Register button with loading state
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _isRegistering ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.6),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isRegistering
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Register',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
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

  Widget _buildBannerImage() {
    final url = widget.imageUrl;
    if (url == null || url.trim().isEmpty) {
      return Center(
        child: Icon(
          Icons.event_available,
          color: widget.tagColor.withValues(alpha: 0.3),
          size: 60,
        ),
      );
    }

    return Image.network(
      url.trim(),
      fit: BoxFit.cover,
      width: double.infinity,
      height: 150,
      // Show a shimmer/spinner while loading
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child; // done loading
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            color: widget.tagColor,
            strokeWidth: 2,
          ),
        );
      },
      // On error, show a friendly placeholder explaining the URL issue
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[100],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link_off_rounded,
                    color: widget.tagColor.withValues(alpha: 0.45), size: 32),
                const SizedBox(height: 6),
                const Text(
                  'Use a direct image URL',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Text(
                    'e.g. from imgur.com or postimg.cc',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

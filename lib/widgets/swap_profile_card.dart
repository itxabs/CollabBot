import 'package:flutter/material.dart';
import 'report_bottom_sheet.dart';

class SwapProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;

  const SwapProfileCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile['name'] ?? 'Collaborator';
    final title = profile['title'] ?? 'Full Stack Developer';
    final distance = profile['distance'] ?? 'Location Hidden';
    
    final description = profile['description'] ?? 'No bio provided.';
    final initials = (name.isNotEmpty) ? name.substring(0, 1).toUpperCase() : 'U';
    
    final skills = profile['skills'] as List? ?? [];
    
    final dpUrl = profile['profile_picture_url'];
    final hasImage = dpUrl != null && dpUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image or Gradient
            if (hasImage)
              Image.network(
                dpUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallback(initials),
              )
            else
              _buildFallback(initials),

            // Gradient Overlay for Text Readability
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0A0B1E).withOpacity(0.95),
                      const Color(0xFF0A0B1E).withOpacity(0.5),
                      Colors.transparent,
                      const Color(0xFF0A0B1E).withOpacity(0.4),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // Distance Badge
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0B1E).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(distance, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),

            // Report Button
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ReportBottomSheet(
                      targetUserId: profile['user_id'],
                      contentType: 'user',
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0B1E).withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag_outlined, color: Colors.white, size: 18),
                ),
              ),
            ),

            // User Info (Bottom)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildSmallBadge(Icons.people_alt_outlined, "${profile['connections_count'] ?? 0} Connections"),
                      const SizedBox(width: 8),
                      _buildSmallBadge(Icons.article_outlined, "${profile['posts_count'] ?? 0} Posts"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (skills.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skills.take(4).map((s) {
                        final skillName = s is Map ? (s['name'] ?? '') : s.toString();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Text(
                            skillName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallback(String initials) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5046E5), Color(0xFF0A0B1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 120,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0B1E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


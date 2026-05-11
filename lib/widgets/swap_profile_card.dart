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
    final starRating = profile['rating']?.toString() ?? '4.8';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            // Top Header with Gradient and Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE0E7FF), Color(0xFFF3E8FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                


                // Distance Badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_outlined, color: Color(0xFFF97316), size: 16),
                        const SizedBox(width: 4),
                        Text(distance, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),

                // Report Button
                Positioned(
                  top: 16,
                  left: 16,
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
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flag_outlined, color: Color(0xFFEF4444), size: 20),
                    ),
                  ),
                ),

                // Avatar in the center
                Positioned(
                  bottom: -40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8B4FE),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                            width: 2),
                        image: profile['profile_picture_url'] != null &&
                                profile['profile_picture_url'].isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(
                                    profile['profile_picture_url']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profile['profile_picture_url'] == null ||
                              profile['profile_picture_url'].isEmpty
                          ? Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Color(0xFF5B21B6),
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),

              ],
            ),
            
            const SizedBox(height: 50),

            // User Info - Scrollable to prevent overflow
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),

                      ],
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFF97316),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSmallBadge(Icons.people_alt_outlined, "${profile['connections_count'] ?? 0} Connections"),
                        const SizedBox(width: 8),
                        _buildSmallBadge(Icons.article_outlined, "${profile['posts_count'] ?? 0} Posts"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, color: Color(0xFF6B7280), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          profile['department'] ?? 'Computer Science',
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Skills Chips
                    if (skills.isNotEmpty) ...[
                      const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF374151))),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills.map((s) {
                          final skillName = s is Map ? (s['name'] ?? '') : s.toString();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE0E7FF)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF5046E5)),
                                const SizedBox(width: 4),
                                Text(
                                  skillName,
                                  style: const TextStyle(
                                    color: Color(0xFF4338CA),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallBadge(IconData icon, String text) {

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

class SwapProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;

  const SwapProfileCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    // Extracting data with safe defaults
    final String name = profile['name'] ?? 'Unknown';
    final String title = profile['title'] ?? 'Collaborator';
    final String degree = profile['degree'] ?? 'Not specified';
    final String description = profile['description'] ?? 'No bio provided.';
    final String rating = profile['rating']?.toString() ?? '4.8';
    final String distance = profile['distance']?.toString() ?? '2.3 km';
    final String initials = profile['initials'] ?? (name.isNotEmpty ? name[0] : 'U');
    final dynamic skillsData = profile['skills'] ?? [];
    final int mentorships = profile['mentorships'] ?? 15;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Gradient Section (Lavender to Peach)
              Container(
                height: 160,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFE9D5FF), // Lavender
                      Color(0xFFFFEDD5), // Peach
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Top Left Rating Badge
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              rating,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold, 
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Top Right Distance Badge
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              distance,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold, 
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom Details Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Sparkle Icon
                        Row(
                          children: [
                            Text(
                              name,
                              style: AppTextStyles.h2.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 24),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Title in Coral/Orange
                        Text(
                          title,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: const Color(0xFFF97316),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Education with Graduation Cap
                        Row(
                          children: [
                            const Icon(Icons.school, color: Color(0xFF9CA3AF), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                degree,
                                style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF6B7280)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Description/Bio
                        Text(
                          description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: const Color(0xFF4B5563),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Skills Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 10,
                          children: _buildSkillChips(skillsData),
                        ),
                        const SizedBox(height: 24),
                        // Stats
                        Row(
                          children: [
                            Text(
                              mentorships.toString(),
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'successful mentorships',
                              style: AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Positioned Avatar (Centered between sections)
          Positioned(
            top: 160 - 55, // 160 is top section height, 55 is half of avatar container
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEDE9FE), // Light purple/lavender
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSkillChips(dynamic skillsData) {
    final List<Widget> chips = [];
    
    if (skillsData is List) {
      for (var skill in skillsData) {
        String skillName = '';
        bool isVerified = true; // Default to true as per design aesthetics

        if (skill is String) {
          skillName = skill;
        } else if (skill is Map) {
          skillName = skill['name']?.toString() ?? '';
          isVerified = skill['type'] == 'verified' || skill['is_verified'] == true;
        }

        if (skillName.isEmpty) continue;

        chips.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4), // Light green background
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isVerified)
                  const Padding(
                    padding: EdgeInsets.only(right: 6.0),
                    child: Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 16),
                  ),
                Text(
                  skillName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF166534), // Dark green text
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    return chips;
  }
}


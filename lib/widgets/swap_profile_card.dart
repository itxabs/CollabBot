import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

class SwapProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;

  const SwapProfileCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Gradient Section
              Container(
                height: 140,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFE6D6F6), // Light purple 
                      Color(0xFFFFE5E0), // Peach
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Top Left Rating
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              profile['rating'] ?? '4.7',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Top Right Distance
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.deepOrange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              profile['distance'] ?? '8.7 km',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
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
                child: Container(
                  padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              profile['name'],
                              style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile['title'],
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.school_outlined, color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              profile['degree'] ?? 'BSCS - 6th Semester',
                              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile['description'],
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (profile['skills'] as List<dynamic>).map((skillInfo) {
                            final name = skillInfo['name'] as String;
                            final type = skillInfo['type'] as String;
                            
                            final isVerified = type == 'verified';
                            final color = isVerified ? Colors.teal : Colors.grey.shade600;
                            final bgColor = isVerified ? Colors.teal.withOpacity(0.1) : Colors.grey.shade100;
                            final icon = isVerified ? Icons.check_circle_outline : Icons.schedule;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, color: color, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    name,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              profile['mentorships']?.toString() ?? '8',
                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'successful mentorships',
                              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
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
          // Positioned Avatar
          Positioned(
            top: 140 - 55, // 140 is the gradient height, 55 is avatar wrapper radius
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE3D6F5), // Light purple interior
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      spreadRadius: 2, // Simulates the outer purple ring
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    profile['initials'] ?? 'FK',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 24,
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
}

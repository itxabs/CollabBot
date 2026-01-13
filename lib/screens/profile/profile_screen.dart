import 'package:collab_bot/core/constants/app_colors.dart';
import 'package:collab_bot/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Purple Header
            Container(
              width: double.infinity,
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7B61FF), Color(0xFF9756FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Profile",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.share, color: Colors.white),
                  ],
                ),
              ),
            ),

            // Profile Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              transform: Matrix4.translationValues(0, -40, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: const Text(
                      "SA",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name & Role
                  const Text(
                    "Shakeel Ahmad",
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Junior Student",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem("1,250", "Points"),
                      _buildStatItem("#12", "Rank"),
                      _buildStatItem("28", "Connect"),
                      _buildStatItem("4.7⭐", "Rating"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Edit Profile Button
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profile"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // About Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "About",
                    style: AppTextStyles.subtitle1,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Aspiring software engineer passionate about AI and mobile development. "
                    "Currently working on my FYP – CollabBot.",
                    style: AppTextStyles.body2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text("Lahore, Pakistan", style: AppTextStyles.body2),
                      SizedBox(width: 16),
                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text("Joined Sep 2025", style: AppTextStyles.body2),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Skills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Skills", style: AppTextStyles.subtitle1),
                      TextButton(
                        onPressed: () {},
                        child: const Text("Verify Skills"),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _SkillChip(label: "Flutter"),
                      _SkillChip(label: "Python"),
                      _SkillChip(label: "Firebase"),
                      _SkillChip(label: "UI/UX"),
                      _SkillChip(label: "Machine Learning"),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Experience
                  const Text("Experience", style: AppTextStyles.subtitle1),
                  const SizedBox(height: 8),
                  _ExperienceTile(
                    title: "Flutter Developer Intern",
                    company: "TechVentures",
                    period: "Jun 2025 - Aug 2025",
                  ),
                  _ExperienceTile(
                    title: "Research Assistant",
                    company: "AI Lab, RIU",
                    period: "Jan 2025 - Present",
                  ),

                  const SizedBox(height: 16),

                  // Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Badges", style: AppTextStyles.subtitle1),
                      Text("3 earned", style: AppTextStyles.body2),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: const [
                      _Badge(label: "Early Adopter"),
                      _Badge(label: "Top Mentee"),
                      _Badge(label: "Skill Master"),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // Widgets
  // -------------------------
  Widget _buildStatItem(String value, String title) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// Skill Chip Widget
class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppColors.primary,
    );
  }
}

// Experience Tile Widget
class _ExperienceTile extends StatelessWidget {
  final String title;
  final String company;
  final String period;
  const _ExperienceTile({
    required this.title,
    required this.company,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTextStyles.body1),
      subtitle: Text(company, style: AppTextStyles.body2),
      trailing: Text(period, style: AppTextStyles.caption),
    );
  }
}

// Badge Widget
class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primary,
          radius: 24,
          child: Icon(Icons.emoji_events, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

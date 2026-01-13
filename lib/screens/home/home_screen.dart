import 'package:collab_bot/view_models/auth_view_model.dart';
import 'package:collab_bot/view_models/user_view_model.dart';
import 'package:collab_bot/widgets/event_card.dart';
import 'package:collab_bot/widgets/quick_action.dart';
import 'package:collab_bot/widgets/stat_item.dart';
import 'package:collab_bot/widgets/suggestion_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    // Load current user after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      final userVM = context.read<UserViewModel>();
      final userId = authVM.currentUser?.userId;

      if (userId != null) {
        userVM.loadUser(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userVM = context.watch<UserViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome back 👋",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              userVM.isLoading
                  ? "Loading..."
                  : userVM.currentUser?.name ?? "User",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          const Icon(Icons.notifications_none, color: Colors.black),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF28A745),
            child: Text(
              userVM.currentUser != null
                  ? userVM.currentUser!.name.substring(0, 2).toUpperCase()
                  : "NA",
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Points Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF9095A1), Color(0xFF171A1F)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Your Points",
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "1,250",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Chip(
                        backgroundColor: Color(0xFF28A745),
                        label: Text(
                          "+120 this week",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatItem(title: "Rank", value: "#12"),
                      StatItem(title: "Connections", value: "28"),
                      StatItem(title: "Verified Skills", value: "5"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// Quick Actions
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                QuickAction(icon: Icons.people, label: "Find Match"),
                QuickAction(icon: Icons.smart_toy, label: "CollabAI"),
                QuickAction(icon: Icons.emoji_events, label: "Leaderboard"),
                QuickAction(icon: Icons.event, label: "Events"),
              ],
            ),

            const SizedBox(height: 24),

            /// Suggested Users
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Suggested for You",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text("See all →", style: TextStyle(color: Color(0xFF28A745))),
              ],
            ),
            const SizedBox(height: 16),
            const SuggestionCard(
              initials: "AK",
              name: "Ahmed Khan",
              role: "Senior Flutter Dev",
              skills: ["Flutter", "Firebase"],
            ),
            const SuggestionCard(
              initials: "SM",
              name: "Sara Malik",
              role: "Alumni UX Designer",
              skills: ["UI/UX", "Figma", "Testing"],
            ),
            const SuggestionCard(
              initials: "AH",
              name: "Ali Hassan",
              role: "Senior ML Engineer",
              skills: ["Python", "TensorFlow"],
            ),

            const SizedBox(height: 24),

            /// Events
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Upcoming Events",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  child: Text(
                    "See all →",
                    style: TextStyle(color: Color(0xFF28A745)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const EventCard(title: "Flutter Workshop", date: "Jan 15 • 3:00 PM"),
            const EventCard(
              title: "AI in Education Seminar",
              date: "Jan 18 • 2:00 PM",
            ),
          ],
        ),
      ),
    );
  }
}

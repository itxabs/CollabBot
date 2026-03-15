import 'package:flutter/material.dart';
import '../../widgets/swap_profile_card.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../data/services/swap_service.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  // Use a Future property so we don't re-fetch on every build
  late Future<List<Map<String, dynamic>>> _recommendationsFuture;
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  void _fetchProfiles() {
    setState(() {
      _isLoading = true;
      _recommendationsFuture = SwapService.getRecommendations().then((data) {
        setState(() {
          _profiles = data;
          _isLoading = false;
        });
        return data;
      }).catchError((error) {
        setState(() {
          _isLoading = false;
        });
        print("Swap UI Load Error: $error");
        return <Map<String, dynamic>>[];
      });
    });
  }

  void _onSwipe(bool isLiked) async {
    if (_profiles.isNotEmpty) {
      final swipedProfile = _profiles[0];
      
      setState(() {
        _profiles.removeAt(0);
      });

      if (isLiked) {
         // Fire and forget the like recording
         SwapService.likeUser(swipedProfile['user_id'] ?? swipedProfile['id']);
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    Color backgroundColor = Colors.white,
    double size = 50.0,
    double iconSize = 24.0,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: iconColor, size: iconSize),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Find Collaborators', style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0, top: 4.0),
          child: Column(
            children: [
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _profiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              'No more profiles around you.',
                              style: AppTextStyles.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        clipBehavior: Clip.none,
                        fit: StackFit.expand,
                        children: _profiles.reversed.map((profile) {
                          final index = _profiles.indexOf(profile);
                          
                          if (index > 2) return const SizedBox.shrink();

                          final isTopCard = index == 0;
                          final offset = index * 12.0;
                          final double scale = 1.0 - (index * 0.05);

                          Widget cardDisplay = Transform.translate(
                            offset: Offset(0, offset),
                            child: Transform.scale(
                              scale: scale,
                              alignment: Alignment.bottomCenter,
                              child: SwapProfileCard(profile: profile),
                            ),
                          );

                          if (isTopCard) {
                            // Ensure key is absolutely unique string
                            final String uniqueKey = profile['user_id']?.toString() ?? profile['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
                            
                            return Positioned.fill(
                              key: Key(uniqueKey),
                              child: Dismissible(
                                key: Key(uniqueKey),
                                direction: DismissDirection.horizontal,
                                onDismissed: (direction) {
                                  // Right swipe == Like, Left swipe == Pass
                                  bool isLiked = direction == DismissDirection.startToEnd;
                                  _onSwipe(isLiked);
                                },
                                child: cardDisplay,
                              ),
                            );
                          }
                          
                          final String bgKey = "\${profile['user_id'] ?? profile['id']}_bg";
                          return Positioned.fill(
                            key: Key(bgKey),
                            child: cardDisplay,
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 32),
              // Action Buttons Row
              if (!_isLoading && _profiles.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      icon: Icons.close,
                      iconColor: Colors.black,
                      borderColor: Colors.grey.shade300,
                      onPressed: () => _onSwipe(false)
                    ),
                    const SizedBox(width: 16),
                    _buildActionButton(
                      icon: Icons.refresh,
                      iconColor: Colors.black,
                      borderColor: Colors.grey.shade300,
                      onPressed: _fetchProfiles
                    ),
                    const SizedBox(width: 16),
                    _buildActionButton(
                      icon: Icons.star_border,
                      iconColor: Colors.orange,
                      borderColor: Colors.orange,
                      size: 56.0,
                      iconSize: 28.0,
                      onPressed: () => _onSwipe(true), // Superlike
                    ),
                    const SizedBox(width: 16),
                    _buildActionButton(
                      icon: Icons.favorite_border,
                      iconColor: Colors.white,
                      backgroundColor: AppColors.primary,
                      borderColor: AppColors.primary,
                      size: 64.0,
                      iconSize: 32.0,
                      onPressed: () => _onSwipe(true), // Like
                    ),
                  ],
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

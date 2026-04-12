import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  late Future<List<Map<String, dynamic>>> _recommendationsFuture;
  List<Map<String, dynamic>> _profiles = [];
  final List<Map<String, dynamic>> _history = []; // For Undo functionality
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      print("Location Error: $e");
      return null;
    }
  }

  void _fetchProfiles() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _getCurrentLocation();
      final data = await SwapService.getRecommendations(
        lat: position?.latitude,
        lng: position?.longitude,
      );
      
      if (mounted) {
        setState(() {
          _profiles = data;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString().contains("Connection refused") 
              ? "Cannot connect to server. Check IP: \${SwapService.baseUrl}" 
              : error.toString();
        });
      }
      print("Swap UI Load Error: $error");
    }
  }

  void _onSwipe(bool isLiked, {bool isSuperLike = false}) async {
    if (_profiles.isNotEmpty) {
      final swipedProfile = _profiles[0];
      
      setState(() {
        _history.add(_profiles.removeAt(0));
      });

      if (isLiked || isSuperLike) {
         final result = await SwapService.likeUser(swipedProfile['user_id'] ?? swipedProfile['id']);
         
         if (result['is_match'] == true) {
           _showMatchDialog(swipedProfile);
         } else if (isSuperLike) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Super Liked ${swipedProfile['name']}!'),
               duration: const Duration(seconds: 1),
               backgroundColor: const Color(0xFFF59E0B),
             ),
           );
         }
      }
    }
  }

  void _showMatchDialog(Map<String, dynamic> profile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 64),
              const SizedBox(height: 16),
              Text(
                "It's a Match!",
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "You and ${profile['name']} have liked each other. You can now start collaborating!",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Keep Swiping"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to Chat or Profile
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Say Hello", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _undoSwipe() {
    if (_history.isNotEmpty) {
      setState(() {
        _profiles.insert(0, _history.removeLast());
      });
    }
  }

  Widget _buildActionButton({
    required Widget icon,
    required Color borderColor,
    Color backgroundColor = Colors.white,
    Gradient? gradient,
    double size = 56.0,
    List<BoxShadow>? extraShadows,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        border: gradient == null ? Border.all(color: borderColor, width: 1.0) : null,
        boxShadow: extraShadows ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: icon,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Find Collaborators', 
          style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF6B7280)), // Filter icon
            onPressed: () {
              // Show filters dialog/bottomsheet
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            children: [
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
                  : _errorMessage != null
                    ? _buildErrorState()
                    : _profiles.isEmpty
                      ? _buildEmptyState()
                      : Stack(
                        clipBehavior: Clip.none,
                        children: _profiles.asMap().entries.map((entry) {
                          int index = entry.key;
                          var profile = entry.value;
                          
                          // Show only top 3 cards for performance
                          if (index > 2) return const SizedBox.shrink();

                          final bool isTopCard = index == 0;
                          final double bottomOffset = index * 15.0;
                          final double scale = 1.0 - (index * 0.05);

                          Widget cardDisplay = Transform.translate(
                            offset: Offset(0, bottomOffset),
                            child: Transform.scale(
                              scale: scale,
                              alignment: Alignment.bottomCenter,
                              child: SwapProfileCard(profile: profile),
                            ),
                          );

                          if (isTopCard) {
                            final String uniqueKey = profile['user_id']?.toString() ?? profile['id']?.toString() ?? profile['name'];
                            return Positioned.fill(
                              key: Key(uniqueKey),
                              child: Dismissible(
                                key: Key(uniqueKey),
                                direction: DismissDirection.horizontal,
                                onDismissed: (direction) {
                                  bool isLiked = direction == DismissDirection.startToEnd;
                                  _onSwipe(isLiked);
                                },
                                child: cardDisplay,
                              ),
                            );
                          }
                          
                          return Positioned.fill(
                            child: cardDisplay,
                          );
                        }).toList().reversed.toList(), // Reversed so index 0 is on top
                      ),
              ),
              const SizedBox(height: 32),
              // Action Buttons Row
              if (!_isLoading && _profiles.isNotEmpty)
                _buildActionButtonsRow(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              "Connection Issue",
              style: AppTextStyles.h3.copyWith(color: Colors.redAccent),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? "Something went wrong",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchProfiles,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
              child: const Text("Try Again", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline, size: 64, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 24),
            Text(
              'No more profiles around you.',
              style: AppTextStyles.h3.copyWith(color: const Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or check back later.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
               onPressed: _fetchProfiles,
               style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(0xFF8B5CF6),
                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
               ),
               child: Text('Refresh Discovery', style: AppTextStyles.button),
            ),
          ],
        ),
      );
  }

  Widget _buildActionButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Dislike Button (X)
        _buildActionButton(
          icon: const Icon(Icons.close, color: Color(0xFF6B7280), size: 28),
          borderColor: const Color(0xFFE5E7EB),
          onPressed: () => _onSwipe(false),
        ),
        // Rewind Button (Undo)
        _buildActionButton(
          icon: Icon(
            Icons.replay, 
            color: _history.isEmpty ? const Color(0xFFD1D5DB) : const Color(0xFF8B5CF6), 
            size: 24
          ),
          borderColor: const Color(0xFFE5E7EB),
          size: 48.0,
          onPressed: _history.isEmpty ? () {} : _undoSwipe,
        ),
        // Super Like Button (Star)
        _buildActionButton(
          icon: const Icon(Icons.star, color: Color(0xFFF59E0B), size: 28),
          borderColor: const Color(0xFFFDE68A),
          onPressed: () => _onSwipe(true, isSuperLike: true),
        ),
        // Like Button (Heart - Primary Gradient)
        _buildActionButton(
          icon: const Icon(Icons.favorite, color: Colors.white, size: 32),
          borderColor: Colors.transparent,
          size: 68.0,
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          extraShadows: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          onPressed: () => _onSwipe(true),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../widgets/swap_profile_card.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/routes.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/swap_service.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _profiles = [];
  final List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _locationUnavailable = false;
  String _activeFilter = 'Meet'; 
  Map<String, dynamic> _counts = {};
  bool _isSaving = false;
  int _savedCount = 0;
  dynamic _realtimeSubscription;

  // Preferences
  double _maxDistance = 50.0;
  List<String> _selectedRoles = [];
  final List<String> _availableRoles = ['Junior', 'Senior', 'Alumni'];

  // Drag state for the top card
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
    _fetchCounts();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  dynamic _matchesSubscription;

  void _setupRealtimeListener() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Listen for new likes targeting the current user
    _realtimeSubscription = Supabase.instance.client
        .from('swipe_actions')
        .stream(primaryKey: ['id'])
        .eq('target_id', user.id)
        .listen((data) {
          print('SwapScreen: Real-time update in swipe_actions');
          _fetchCounts();
        });

    // Listen for new matches
    _matchesSubscription = Supabase.instance.client
        .from('matches')
        .stream(primaryKey: ['id'])
        .listen((data) {
          print('SwapScreen: Real-time update in matches');
          _fetchCounts();
        });

  }

  void _resetAllSwipes() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      // We'll call a new endpoint or just truncate via Supabase client if permissions allow
      // For safety, let's assume we need a backend endpoint or a loop
      // But since we want to avoid SQL, let's just use the 'restore' action in a loop or a new endpoint
      
      // I'll add a "reset" endpoint to the backend for convenience
      final url = Uri.parse('${SwapService.baseUrl}/swap/reset?user_id=${user.id}');
      final response = await http.post(url);
      
      if (response.statusCode == 200) {
        _fetchProfiles();
        _fetchCounts();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Swipes reset successfully!')));
      }
    } catch (e) {
      print('Reset error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _fetchCounts() async {
    final counts = await SwapService.getCounts();
    if (mounted) {
      setState(() => _counts = counts);
    }
  }


  // ─── Location ─────────────────────────────────────────────────────────────

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationUnavailable = true);
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationUnavailable = true);
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _locationUnavailable = true);
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (e) {
      print('Location Error: $e');
      setState(() => _locationUnavailable = true);
      return null;
    }
  }

  // ─── Fetch ─────────────────────────────────────────────────────────────────

  void _fetchProfiles() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _locationUnavailable = false;
    });

    try {
      final position = await _getCurrentLocation();

      if (position != null) {
        await SwapService.updateUserLocation(
            position.latitude, position.longitude);
      }

      final data = await SwapService.getRecommendations(
        lat: position?.latitude,
        lng: position?.longitude,
        filterType: _activeFilter,
        roles: _selectedRoles,
        maxDist: _maxDistance,
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
          _errorMessage = error.toString().contains('Connection refused')
              ? 'Cannot connect to server.\nCheck backend: ${SwapService.baseUrl}'
              : error.toString();
        });
      }
      print('Swap UI Load Error: $error');
    }
  }

  // ─── Swipe Logic ───────────────────────────────────────────────────────────

  void _handleSwipe(bool direction) {
    if (_profiles.isEmpty) return;

    final targetOffset = direction 
        ? const Offset(600, -200) // Diagonal Right (Send/Like)
        : const Offset(-600, 0); // Horizontal Left (Pass)

    setState(() {
      _dragOffset = targetOffset;
      _dragAngle = direction ? 0.3 : -0.3;
    });

    Future.delayed(const Duration(milliseconds: 300), () async {
      if (mounted) {
        final profile = _profiles[0];
        _history.add(profile);
        _profiles.removeAt(0);
        _dragOffset = Offset.zero;
        _dragAngle = 0.0;
        _isDragging = false;
        setState(() {});
        
        // Record action to backend
        final result = await SwapService.swipeUser(profile['user_id'] ?? profile['id'], action: direction ? 'like' : 'reject');
        
        // Refresh counts immediately after swiping
        _fetchCounts();
        
        if (direction && result['is_match'] == true && mounted) {
           _showMatchDialog(profile);
        }
      }
    });
  }

  void _undoSwipe() {
    if (_history.isNotEmpty) {
      setState(() {
        _profiles.insert(0, _history.removeLast());
      });
    }
  }

  // ─── Drag Gesture ──────────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      _dragAngle = (_dragOffset.dx / 300).clamp(-0.4, 0.4);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    const double swipeThreshold = 100.0;
    final double velocity = details.velocity.pixelsPerSecond.dx;

    if (_dragOffset.dx > swipeThreshold || velocity > 500) {
      _handleSwipe(true);
    } else if (_dragOffset.dx < -swipeThreshold || velocity < -500) {
      _handleSwipe(false);
    } else {
      setState(() {
        _dragOffset = Offset.zero;
        _dragAngle = 0.0;
        _isDragging = false;
      });
    }
  }

  // ─── Match Dialog ──────────────────────────────────────────────────────────

  void _showMatchDialog(Map<String, dynamic> profile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(Icons.handshake_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                "It's a Match! 🎉",
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You and ${profile['name']} both want to collaborate! Start a conversation.",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: const Color(0xFF6B7280), height: 1.6),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Keep Swiping',
                          style: TextStyle(color: Color(0xFF6B7280))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Say Hello 👋',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600)),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _openChatWithMatchedUser(profile);
                      },
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

  // ─── UI Helpers ────────────────────────────────────────────────────────────

  Future<void> _openChatWithMatchedUser(Map<String, dynamic> profile) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again to start chat.')),
      );
      return;
    }

    final matchedUserId =
        (profile['user_id'] ?? profile['id'])?.toString().trim();
    final matchedUserName = (profile['name'] ?? 'Chat').toString().trim();

    if (matchedUserId == null || matchedUserId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open chat for this match.')),
      );
      return;
    }

    try {
      final chatService = ChatService(Supabase.instance.client);
      final chatId = await chatService.createOrGetChat(
        currentUser.id,
        matchedUserId,
      );

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.chat,
        arguments: {
          'chatId': chatId,
          'otherName': matchedUserName.isEmpty ? 'Chat' : matchedUserName,
          'otherUserId': matchedUserId,
          'otherUserRole': profile['role']?.toString(),
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open chat: $e')));
    }
  }

  double get _overlayOpacity {
    return (_dragOffset.dx.abs() / 120).clamp(0.0, 1.0);
  }

  bool get _isDraggingRight => _dragOffset.dx > 10;
  bool get _isDraggingLeft => _dragOffset.dx < -10;

  Widget _buildActionButtonsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton(
            icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 36),
            backgroundColor: Colors.white,
            borderColor: Colors.red.shade100,
            onPressed: () => _handleSwipe(false),
            size: 72,
          ),
          _buildActionButton(
            icon: const Icon(Icons.favorite_rounded, color: Color(0xFF5046E5), size: 36),
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFE0E7FF),
            onPressed: () => _handleSwipe(true),
            size: 72,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required Widget icon,
    required Color backgroundColor,
    required Color borderColor,
    required VoidCallback onPressed,
    double size = 64,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: icon),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.tune_rounded, color: Color(0xFF0A0B1E)),
          onPressed: _showPreferencesSheet,
        ),
        title: const Text(
          'Find Collaborator',
          style: TextStyle(
            color: Color(0xFF0A0B1E),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0A0B1E)),
            onPressed: _showHistorySheet,
            tooltip: 'Swipe History',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterPills(),
            if (_locationUnavailable && !_isLoading)
              _buildLocationBanner(),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 8),
                child: Column(
                  children: [
                    Expanded(child: _buildCardStack()),
                    const SizedBox(height: 16),
                    if (!_isLoading && _errorMessage == null && _profiles.isNotEmpty)
                      _buildActionButtonsRow(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterPill('Meet', count: _counts['Meet']?.toString()),
          const SizedBox(width: 8),
          _filterPill('Waves', count: _counts['Waves']?.toString()),
          const SizedBox(width: 8),
          _filterPill('Views', count: _counts['Views']?.toString()),
          const SizedBox(width: 8),
          _filterPill('Newbies', count: _counts['Newbies']?.toString()),
        ],
      ),
    );
  }

  Widget _filterPill(String label, {String? count}) {
    final bool isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = label;
          _fetchProfiles();
        });

        if (label == 'Waves') {
          _showLongSnackBar('See who waved at you 👋');
        } else if (label == 'Views') {
          _showLongSnackBar('See who viewed your profile 👁️');
        } else if (label == 'Newbies') {
          _showLongSnackBar('See all Newbies 🆕');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF5046E5) : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF6B7280),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Text(
                count,
                style: TextStyle(
                  color: isActive ? Colors.white70 : const Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLongSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 50),
        backgroundColor: const Color(0xFF5046E5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showPreferencesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildPreferencesSheet(),
    );
  }

  Widget _buildPreferencesSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) => Container(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Preferences', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _fetchProfiles();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFEEF2FF),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF5046E5))),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Search Distance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                Text('${_maxDistance.round()} km', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5046E5))),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF5046E5),
                inactiveTrackColor: const Color(0xFFEEF2FF),
                thumbColor: Colors.white,
                overlayColor: const Color(0xFF5046E5).withOpacity(0.1),
                trackHeight: 6.0,
              ),
              child: Slider(
                value: _maxDistance,
                max: 500,
                divisions: 10,
                onChanged: (v) => setSheetState(() => _maxDistance = v),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Collaborator Roles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableRoles.map((role) {
                final isSelected = _selectedRoles.contains(role);
                return GestureDetector(
                  onTap: () {
                    setSheetState(() {
                      if (isSelected) {
                        _selectedRoles.remove(role);
                      } else {
                        _selectedRoles.add(role);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF5046E5) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF5046E5) : const Color(0xFFE5E7EB),
                        width: 1.5,
                      ),
                      boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF5046E5).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))] : [],
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF4B5563),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _resetAllSwipes();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Reset All Swipes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _HistorySheet(),
    );
  }


  void _showProfileDetails(Map<String, dynamic> profile) {
    // Record view in background
    SwapService.recordProfileView(profile['user_id'] ?? profile['id']);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProfileDetailSheet(profile: profile),
    );
  }

  Widget _buildLocationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF5046E5).withOpacity(0.05),
      child: Row(
        children: [
          const Icon(Icons.location_off_rounded, color: Color(0xFF5046E5), size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Enable location for nearby collaborators',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: () async {
              await Geolocator.openLocationSettings();
            },
            child: const Text(
              'Enable',
              style: TextStyle(
                color: Color(0xFF5046E5),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5046E5)),
      );
    }

    if (_errorMessage != null) return _buildErrorState();
    if (_profiles.isEmpty) return _buildEmptyState();

    return Stack(
      children: [
        const Opacity(opacity: 0.0, child: SizedBox.expand()),

        if (_profiles.length > 1)
          Positioned(
            top: 20,
            bottom: 0,
            left: 20,
            right: -20,
            child: Transform.scale(
              scale: 0.9,
              child: Opacity(
                opacity: 0.5,
                child: SwapProfileCard(profile: _profiles[1]),
              ),
            ),
          ),

        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (_profiles.isNotEmpty) {
                _showProfileDetails(_profiles[0]);
              }
            },
            onPanStart: _onDragStart,
            onPanUpdate: _onDragUpdate,
            onPanEnd: _onDragEnd,
            child: Transform.translate(
              offset: _dragOffset,
              child: Transform.rotate(
                angle: _dragAngle,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SwapProfileCard(profile: _profiles[0]),
                    ),

                    if (_isDraggingRight || _isDraggingLeft)
                      Positioned(
                        top: 40,
                        right: 40,
                        child: Opacity(
                          opacity: _overlayOpacity.clamp(0.0, 1.0),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF5046E5),
                            ),
                            child: const Center(
                              child: Text(
                                'NEXT +',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 56, color: Color(0xFF5046E5)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Connection Issue',
              style: TextStyle(color: Color(0xFF0A0B1E), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchProfiles,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5046E5),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_alt_outlined, size: 64, color: Color(0xFF5046E5)),
          ),
          const SizedBox(height: 24),
          const Text(
            "You're all caught up!",
            style: TextStyle(color: Color(0xFF0A0B1E), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Check back later for new matches.",
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _fetchProfiles,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5046E5),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            child: const Text('Refresh Discovery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailSheet extends StatefulWidget {
  final Map<String, dynamic> profile;
  const _ProfileDetailSheet({required this.profile});

  @override
  State<_ProfileDetailSheet> createState() => _ProfileDetailSheetState();
}

class _ProfileDetailSheetState extends State<_ProfileDetailSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _userEvents = [];
  bool _loadingEvents = true;
  List<Map<String, dynamic>> _matches = [];
  bool _loadingMatches = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserEvents();
    _fetchMatches();
  }

  void _fetchUserEvents() async {
    final events = await SwapService.getUserEvents(widget.profile['user_id'] ?? widget.profile['id']);
    if (mounted) {
      setState(() {
        _userEvents = events;
        _loadingEvents = false;
      });
    }
  }

  void _fetchMatches() async {
    final matches = await SwapService.getMatches();
    if (mounted) {
      setState(() {
        _matches = matches;
        _loadingMatches = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                   Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFFEEF2FF),
                        backgroundImage: widget.profile['profile_picture_url'] != null && widget.profile['profile_picture_url'].isNotEmpty
                            ? NetworkImage(widget.profile['profile_picture_url'])
                            : null,
                        child: widget.profile['profile_picture_url'] == null || widget.profile['profile_picture_url'].isEmpty
                            ? Text(widget.profile['initials'] ?? 'U', style: const TextStyle(color: Color(0xFF5046E5), fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${widget.profile['name']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            Text(widget.profile['title'] ?? 'Collaborator', style: const TextStyle(color: Color(0xFF6B7280))),

                          ],
                        ),
                      ),

                    ],
                  ),
                  const SizedBox(height: 24),
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF5046E5),
                    unselectedLabelColor: const Color(0xFF6B7280),
                    indicatorColor: const Color(0xFF5046E5),
                    tabs: const [
                      Tab(text: 'About'),
                      Tab(text: 'Posts'),
                      Tab(text: 'Connection'),
                    ],
                  ),
                  SizedBox(
                    height: 500,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAboutTab(),
                        _buildPostsTab(),
                        _buildConnectionTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    final skills = widget.profile['skills'] as List? ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Experience', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.profile['description'] ?? 'No experience info', style: const TextStyle(color: Color(0xFF4B5563))),
          const SizedBox(height: 20),
          const Text('Skills', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((s) {
              final skillName = s is Map ? (s['name'] ?? '') : s.toString();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(skillName, style: const TextStyle(color: Color(0xFF5046E5), fontSize: 13)),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Education', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.profile['degree'] ?? 'Not provided', style: const TextStyle(color: Color(0xFF4B5563))),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_loadingEvents) return const Center(child: CircularProgressIndicator());
    if (_userEvents.isEmpty) return const Center(child: Text('No posts yet'));
    
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: _userEvents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = _userEvents[index];
        return GestureDetector(
          onTap: () {
            // Logic to navigate to event details if needed
             Navigator.pushNamed(context, AppRoutes.events, arguments: {'eventId': event['id']});
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['title'] ?? 'Untitled Event', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(event['date'] ?? '', style: const TextStyle(color: Color(0xFF5046E5), fontSize: 13)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionTab() {
    if (_loadingMatches) return const Center(child: CircularProgressIndicator());
    if (_matches.isEmpty) return const Center(child: Text('No mutual connections yet. Start swiping!'));

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: _matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final match = _matches[index];
        return ListTile(
          leading: CircleAvatar(
             backgroundImage: match['profile_picture_url'] != null && match['profile_picture_url'].isNotEmpty
                            ? NetworkImage(match['profile_picture_url'])
                            : null,
            child: match['profile_picture_url'] == null || match['profile_picture_url'].isEmpty
                            ? Text(match['initials'] ?? 'U')
                            : null,
          ),
          title: Text(match['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(match['role'] ?? 'Collaborator'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
             // Optional: Navigate to matched user profile
          },
        );
      },
    );
  }
}

class _HistorySheet extends StatefulWidget {
  const _HistorySheet();

  @override
  State<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<_HistorySheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _liked = [];
  List<Map<String, dynamic>> _passed = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final response = await Supabase.instance.client
          .from('swipe_actions')
          .select('action, created_at, target_id')
          .eq('actor_id', user.id)
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        if (mounted) setState(() { _isLoading = false; });
        return;
      }

      final targetIds = response.map((r) => r['target_id'].toString()).toSet().toList();
      
      final usersResponse = await Supabase.instance.client
          .from('users')
          .select()
          .filter('id', 'in', targetIds);

      final usersMap = {for (var u in usersResponse) u['id'].toString(): u};

      final List<Map<String, dynamic>> liked = [];
      final List<Map<String, dynamic>> passed = [];

      for (var row in response) {
        final targetId = row['target_id'].toString();
        final target = usersMap[targetId];
        if (target == null) continue;
        
        final data = {
          'id': target['id'],
          'name': target['full_name'] ?? 'User',
          'role': target['role'] ?? 'Collaborator',
          'avatar_url': target['profile_picture_url'] ?? target['avatar_url'],
          'action': row['action'],
          'date': row['created_at'],
        };
        
        if (row['action'] == 'like') {
          liked.add(data);
        } else {
          passed.add(data);
        }
      }

      if (mounted) {
        setState(() {
          _liked = liked;
          _passed = passed;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching history: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Swipe History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const TabBar(
              labelColor: Color(0xFF5046E5),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF5046E5),
              tabs: [
                Tab(text: 'Liked'),
                Tab(text: 'Passed'),
              ],
            ),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      _buildList(_liked, Icons.favorite, Colors.pink),
                      _buildList(_passed, Icons.close, Colors.grey),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, IconData icon, Color iconColor) {
    if (items.isEmpty) {
      return Center(child: Text('No history found.', style: TextStyle(color: Colors.grey.shade600)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];
        final initials = (item['name'] as String).isNotEmpty ? (item['name'] as String)[0].toUpperCase() : 'U';
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFEEF2FF),
            backgroundImage: (item['avatar_url'] != null && (item['avatar_url'] as String).isNotEmpty) ? NetworkImage(item['avatar_url']) : null,
            child: (item['avatar_url'] == null || (item['avatar_url'] as String).isEmpty) ? Text(initials, style: const TextStyle(color: Color(0xFF5046E5), fontWeight: FontWeight.bold)) : null,
          ),
          title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(item['role']),
          trailing: Icon(icon, color: iconColor, size: 20),
        );
      },
    );
  }
}

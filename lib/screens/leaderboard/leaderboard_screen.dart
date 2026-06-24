import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;
  List<_LeaderboardEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _entries = await _loadAggregatedLeaderboard();
    } catch (error) {
      _entries = [];
      _errorMessage = 'Failed to load leaderboard: $error';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<List<_LeaderboardEntry>> _loadAggregatedLeaderboard() async {
    try {
      final response = await _supabase
          .from('leaderboard_scores_summary')
          .select()
          .order('lifetime_score', ascending: false);

      final rows = List<Map<String, dynamic>>.from(response as List);
      return rows.map(_LeaderboardEntry.fromMap).toList();
    } on PostgrestException catch (error) {
      if (!_isMissingSummaryView(error)) rethrow;
      return _loadRawLeaderboard();
    }
  }

  Future<List<_LeaderboardEntry>> _loadRawLeaderboard() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    final response = await _supabase
        .from('leaderboard_scores_log')
        .select(
          'user_id, points, action_type, created_at, users(full_name, role, avatar_url)',
        )
        .order('created_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(response as List);
    return _buildAggregatedEntries(rows, currentUserId);
  }

  bool _isMissingSummaryView(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == '42P01' ||
        message.contains('leaderboard_scores_summary') ||
        message.contains('could not find the table');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: _buildHeader(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildTabSwitcher(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _ErrorState(message: _errorMessage!, onRetry: _loadLeaderboard)
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _LeaderboardTab(
                              entries: _sortedEntries((entry) => entry.weeklyScore),
                              scoreLabel: 'Weekly score',
                            ),
                            _LeaderboardTab(
                              entries: _sortedEntries((entry) => entry.monthlyScore),
                              scoreLabel: 'Monthly score',
                            ),
                            _LeaderboardTab(
                              entries: _sortedEntries((entry) => entry.lifetimeScore),
                              scoreLabel: 'Lifetime score',
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  List<_LeaderboardEntry> _sortedEntries(int Function(_LeaderboardEntry entry) selector) {
    final sorted = [..._entries]..sort((a, b) => selector(b).compareTo(selector(a)));
    return sorted.asMap().entries.map((entry) {
      return entry.value.copyWith(rank: entry.key + 1);
    }).toList();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<_LeaderboardEntry> _buildAggregatedEntries(
    List<Map<String, dynamic>> rows,
    String? currentUserId,
  ) {
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);
    final aggregates = <String, _LeaderboardAggregate>{};

    for (final row in rows) {
      final userId = row['user_id']?.toString();
      if (userId == null || userId.isEmpty) continue;

      final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '') ?? now;
      final points = _toInt(row['points']);
      final user = _extractUser(row['users']);

      final aggregate = aggregates.putIfAbsent(
        userId,
        () => _LeaderboardAggregate(
          userId: userId,
          name: user.name,
          role: user.role,
          avatarUrl: user.avatarUrl,
          updatedAt: createdAt,
        ),
      );

      aggregate.addPoints(
        points: points,
        createdAt: createdAt,
        weekStart: weekStart,
        monthStart: monthStart,
      );
    }

    final entries = aggregates.values.map((aggregate) {
      return _LeaderboardEntry(
        rank: 0,
        userId: aggregate.userId,
        name: aggregate.name.isEmpty ? 'Unknown User' : aggregate.name,
        role: aggregate.role.isEmpty ? 'Member' : aggregate.role,
        avatarUrl: aggregate.avatarUrl,
        weeklyScore: aggregate.weeklyScore,
        monthlyScore: aggregate.monthlyScore,
        lifetimeScore: aggregate.lifetimeScore,
        updatedAt: aggregate.updatedAt,
        isCurrentUser: currentUserId != null && currentUserId == aggregate.userId,
        avatarTint: _LeaderboardEntry.avatarTintFor(aggregate.userId),
      );
    }).toList();

    entries.sort((a, b) => b.lifetimeScore.compareTo(a.lifetimeScore));
    return entries;
  }

  _UserProfileLite _extractUser(dynamic userData) {
    if (userData is Map<String, dynamic>) {
      return _UserProfileLite.fromMap(userData);
    }
    if (userData is List && userData.isNotEmpty && userData.first is Map) {
      return _UserProfileLite.fromMap(Map<String, dynamic>.from(userData.first as Map));
    }
    return const _UserProfileLite();
  }

  Widget _buildHeader() {
    final weeklyTop = _entries.isEmpty
        ? null
        : _entries.reduce((a, b) => a.weeklyScore >= b.weeklyScore ? a : b);
    final currentUser = _entries.where((entry) => entry.isCurrentUser).toList();
    final currentUserRank = currentUser.isEmpty
        ? null
        : _sortedEntries((entry) => entry.lifetimeScore)
            .firstWhere((entry) => entry.isCurrentUser)
            .rank;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6C63D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leaderboard',
                      style: AppTextStyles.h2.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Live rankings from your Supabase score table.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.82),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryChip(
                  label: 'Your rank',
                  value: currentUserRank == null ? 'N/A' : '#$currentUserRank',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryChip(
                  label: 'Top weekly',
                  value: weeklyTop == null ? '0 pts' : '${weeklyTop.weeklyScore} pts',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.16),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
        ),
        tabs: const [
          Tab(text: 'Weekly'),
          Tab(text: 'Monthly'),
          Tab(text: 'All Time'),
        ],
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final List<_LeaderboardEntry> entries;
  final String scoreLabel;

  const _LeaderboardTab({
    required this.entries,
    required this.scoreLabel,
  });

  @override
  Widget build(BuildContext context) {
    final podium = entries.length >= 3 ? entries.take(3).toList(growable: false) : <_LeaderboardEntry>[];
    final rankingEntries = entries.length >= 3 ? entries.skip(3).toList(growable: false) : entries;

    return RefreshIndicator(
      onRefresh: () async {
        final state = context.findAncestorStateOfType<_LeaderboardScreenState>();
        await state?._loadLeaderboard();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        children: [
          if (entries.isEmpty)
            const _EmptyLeaderboardState()
          else ...[
            if (podium.isNotEmpty) ...[
              _Podium(entries: podium, scoreLabel: scoreLabel),
              const SizedBox(height: 20),
            ],
            Text(
              entries.length >= 3 ? 'Full Rankings' : 'Rankings',
              style: AppTextStyles.h3.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            ...rankingEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RankingCard(entry: entry, scoreLabel: scoreLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<_LeaderboardEntry> entries;
  final String scoreLabel;

  const _Podium({required this.entries, required this.scoreLabel});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    if (entries.length == 1) {
      return _SinglePodium(entry: entries.first, scoreLabel: scoreLabel);
    }

    if (entries.length == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumSpot(
              entry: entries[1],
              scoreLabel: scoreLabel,
              height: 92,
              color: const Color(0xFFAEC0D4),
              position: '2',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PodiumSpot(
              entry: entries[0],
              scoreLabel: scoreLabel,
              height: 124,
              color: const Color(0xFFFFB000),
              position: '1',
              highlighted: true,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _PodiumSpot(
            entry: entries[1],
            scoreLabel: scoreLabel,
            height: 92,
            color: const Color(0xFFAEC0D4),
            position: '2',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PodiumSpot(
            entry: entries[0],
            scoreLabel: scoreLabel,
            height: 124,
            color: const Color(0xFFFFB000),
            position: '1',
            highlighted: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PodiumSpot(
            entry: entries[2],
            scoreLabel: scoreLabel,
            height: 76,
            color: const Color(0xFFFF7A1A),
            position: '3',
          ),
        ),
      ],
    );
  }
}

class _SinglePodium extends StatelessWidget {
  final _LeaderboardEntry entry;
  final String scoreLabel;

  const _SinglePodium({required this.entry, required this.scoreLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 140,
        child: _PodiumSpot(
          entry: entry,
          scoreLabel: scoreLabel,
          height: 124,
          color: const Color(0xFFFFB000),
          position: '1',
          highlighted: true,
        ),
      ),
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  final _LeaderboardEntry entry;
  final String scoreLabel;
  final double height;
  final Color color;
  final String position;
  final bool highlighted;

  const _PodiumSpot({
    required this.entry,
    required this.scoreLabel,
    required this.height,
    required this.color,
    required this.position,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: highlighted ? 24 : 20,
          backgroundColor: entry.avatarTint,
          backgroundImage: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
              ? NetworkImage(entry.avatarUrl!)
              : null,
          child: entry.avatarUrl == null || entry.avatarUrl!.isEmpty
              ? Text(
                  entry.initials,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          entry.name,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '${entry.scoreFor(scoreLabel).toStringAsFixed(0)} pts',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 10),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.22),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            position,
            style: AppTextStyles.h2.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _RankingCard extends StatelessWidget {
  final _LeaderboardEntry entry;
  final String scoreLabel;

  const _RankingCard({
    required this.entry,
    required this.scoreLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser = entry.isCurrentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrentUser ? AppColors.primary : AppColors.border,
          width: isCurrentUser ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              '${entry.rank}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 18,
            backgroundColor: entry.avatarTint,
            backgroundImage: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
                ? NetworkImage(entry.avatarUrl!)
                : null,
            child: entry.avatarUrl == null || entry.avatarUrl!.isEmpty
                ? Text(
                    entry.initials,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentUser ? '${entry.name} (You)' : entry.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.role,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.scoreFor(scoreLabel).toStringAsFixed(0)}',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatUpdatedAt(entry.updatedAt),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatUpdatedAt(DateTime updatedAt) {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.78),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLeaderboardState extends StatelessWidget {
  const _EmptyLeaderboardState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events_outlined, color: AppColors.primary, size: 32),
          const SizedBox(height: 10),
          Text(
            'No scores yet',
            style: AppTextStyles.h3.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'This leaderboard will populate once users earn scores.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.bodyLarge),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardEntry {
  final int rank;
  final String userId;
  final String name;
  final String role;
  final String? avatarUrl;
  final int weeklyScore;
  final int monthlyScore;
  final int lifetimeScore;
  final DateTime updatedAt;
  final bool isCurrentUser;
  final Color avatarTint;

  const _LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.weeklyScore,
    required this.monthlyScore,
    required this.lifetimeScore,
    required this.updatedAt,
    required this.isCurrentUser,
    required this.avatarTint,
  });

  factory _LeaderboardEntry.fromMap(Map<String, dynamic> json) {
    final userData = json['users'];
    final user = userData is Map<String, dynamic>
        ? userData
        : userData is List && userData.isNotEmpty && userData.first is Map
            ? Map<String, dynamic>.from(userData.first as Map)
            : <String, dynamic>{};

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final fullName =
        ((json['full_name'] ?? user['full_name']) as String?)?.trim() ?? '';
    final role = ((json['role'] ?? user['role']) as String?)?.trim() ?? 'Member';
    final avatarUrl = (json['avatar_url'] ?? user['avatar_url']) as String?;
    final userId = json['user_id']?.toString() ?? '';

    return _LeaderboardEntry(
      rank: 0,
      userId: userId,
      name: fullName.isEmpty ? 'Unknown User' : fullName,
      role: role.isEmpty ? 'Member' : role,
      avatarUrl: avatarUrl,
      weeklyScore: _toInt(json['weekly_score']),
      monthlyScore: _toInt(json['monthly_score']),
      lifetimeScore: _toInt(json['lifetime_score']),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      isCurrentUser: currentUserId != null && currentUserId == userId,
      avatarTint: avatarTintFor(userId),
    );
  }

  _LeaderboardEntry copyWith({int? rank}) {
    return _LeaderboardEntry(
      rank: rank ?? this.rank,
      userId: userId,
      name: name,
      role: role,
      avatarUrl: avatarUrl,
      weeklyScore: weeklyScore,
      monthlyScore: monthlyScore,
      lifetimeScore: lifetimeScore,
      updatedAt: updatedAt,
      isCurrentUser: isCurrentUser,
      avatarTint: avatarTint,
    );
  }

  int scoreFor(String scoreLabel) {
    switch (scoreLabel) {
      case 'Weekly score':
        return weeklyScore;
      case 'Monthly score':
        return monthlyScore;
      default:
        return lifetimeScore;
    }
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Color avatarTintFor(String seed) {
    final palette = <Color>[
      const Color(0xFFF2EDFF),
      const Color(0xFFE8F6F1),
      const Color(0xFFFFF2E8),
      const Color(0xFFE8F0FF),
    ];
    return palette[seed.hashCode.abs() % palette.length];
  }
}

class _LeaderboardAggregate {
  final String userId;
  String name;
  String role;
  String? avatarUrl;
  int weeklyScore;
  int monthlyScore;
  int lifetimeScore;
  DateTime updatedAt;

  _LeaderboardAggregate({
    required this.userId,
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.updatedAt,
  })  : weeklyScore = 0,
        monthlyScore = 0,
        lifetimeScore = 0;

  void addPoints({
    required int points,
    required DateTime createdAt,
    required DateTime weekStart,
    required DateTime monthStart,
  }) {
    lifetimeScore += points;
    if (createdAt.isAfter(weekStart)) {
      weeklyScore += points;
    }
    if (createdAt.isAfter(monthStart) || createdAt.isAtSameMomentAs(monthStart)) {
      monthlyScore += points;
    }
    if (createdAt.isAfter(updatedAt)) {
      updatedAt = createdAt;
    }
  }
}

class _UserProfileLite {
  final String name;
  final String role;
  final String? avatarUrl;

  const _UserProfileLite({
    this.name = '',
    this.role = '',
    this.avatarUrl,
  });

  factory _UserProfileLite.fromMap(Map<String, dynamic> json) {
    return _UserProfileLite(
      name: (json['full_name'] as String?)?.trim() ?? '',
      role: (json['role'] as String?)?.trim() ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

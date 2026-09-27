import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_follow_button.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/auth_provider.dart';
import '../models/user_relationship_models.dart';
import '../provider/profile_provider.dart';
import '../services/user_relationship_service.dart';
import 'user_profile_screen.dart';

class FollowersFollowingScreen extends StatefulWidget {
  const FollowersFollowingScreen({
    this.initialTabIndex = 0,
    this.userId,
    this.username,
    super.key,
  });

  final int initialTabIndex;
  final String? userId;
  final String? username;

  @override
  State<FollowersFollowingScreen> createState() =>
      _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen> {
  late int _selectedTab;
  late final TextEditingController _searchController;
  late final UserRelationshipService _service;

  List<UserRelationItem> _followers = <UserRelationItem>[];
  List<UserRelationItem> _following = <UserRelationItem>[];
  List<FollowRequestItem> _requests = <FollowRequestItem>[];

  bool _isLoadingFollowers = false;
  bool _isLoadingFollowing = false;
  bool _isLoadingRequests = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _searchController = TextEditingController();
    _service = UserRelationshipService(context.read<ApiClient>());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _myUserId {
    final String? authId = context.read<AuthProvider>().userId;
    if (authId != null && authId.trim().isNotEmpty) return authId.trim();
    final String? profileId = context.read<ProfileProvider>().profile?.id;
    if (profileId != null && profileId.trim().isNotEmpty) return profileId.trim();
    return '';
  }

  String get _myUsername {
    final String? authUsername = context.read<AuthProvider>().user?.displayName;
    final String profileUsername = context.read<ProfileProvider>().username;
    final String candidate = (profileUsername.isNotEmpty ? profileUsername : (authUsername ?? ''))
        .replaceAll('@', '')
        .trim()
        .toLowerCase();
    return candidate;
  }

  bool _isMe(UserRelationItem user) {
    final String myId = _myUserId;
    if (myId.isNotEmpty && user.userId.trim() == myId) {
      return true;
    }
    final String myUsername = _myUsername;
    final String itemUsername =
        user.username.replaceAll('@', '').trim().toLowerCase();
    if (myUsername.isNotEmpty &&
        itemUsername.isNotEmpty &&
        itemUsername == myUsername) {
      return true;
    }
    return false;
  }

  String get _effectiveUserId {
    if (widget.userId != null && widget.userId!.trim().isNotEmpty) {
      return widget.userId!.trim();
    }
    return _myUserId;
  }

  bool get _isOwnProfile {
    final String myId = _myUserId;
    if (widget.userId == null || widget.userId!.trim().isEmpty) return true;
    if (myId.isNotEmpty && widget.userId!.trim() == myId) return true;
    final String myUsername = _myUsername;
    if (widget.username != null &&
        myUsername.isNotEmpty &&
        widget.username!.replaceAll('@', '').trim().toLowerCase() == myUsername) {
      return true;
    }
    return false;
  }

  Future<void> _loadData() async {
    final String targetId = _effectiveUserId;
    if (targetId.isEmpty) return;

    if (_isOwnProfile) {
      _loadRequests();
    }

    if (_selectedTab == 0) {
      await _loadFollowers(targetId);
    } else if (_selectedTab == 1) {
      await _loadFollowing(targetId);
    } else if (_selectedTab == 2) {
      await _loadRequests();
    }
  }

  Future<void> _loadFollowers(String userId) async {
    setState(() => _isLoadingFollowers = true);
    try {
      final List<UserRelationItem> items = await _service.getFollowers(userId);
      if (mounted) {
        final ProfileProvider profile = context.read<ProfileProvider>();
        setState(() {
          _followers = items.map((UserRelationItem u) {
            final bool isF = profile.isFollowingUser(userId: u.userId, username: u.username) || u.isFollowing;
            return u.copyWith(isFollowing: isF);
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('⚠️ [FollowersFollowingScreen] Could not load followers: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFollowers = false);
    }
  }

  Future<void> _loadFollowing(String userId) async {
    setState(() => _isLoadingFollowing = true);
    try {
      final List<UserRelationItem> items = await _service.getFollowing(userId);
      if (mounted) {
        final ProfileProvider profile = context.read<ProfileProvider>();
        setState(() {
          _following = items.map((UserRelationItem u) {
            final bool isF = _isOwnProfile
                ? true
                : (profile.isFollowingUser(userId: u.userId, username: u.username) || u.isFollowing);
            return u.copyWith(isFollowing: isF);
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('⚠️ [FollowersFollowingScreen] Could not load following: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFollowing = false);
    }
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoadingRequests = true);
    try {
      final List<FollowRequestItem> items = await _service.getFollowRequests();
      if (mounted) {
        setState(() {
          _requests = items;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [FollowersFollowingScreen] Could not load requests: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _acceptRequest(FollowRequestItem req) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() {
      _requests.removeWhere((FollowRequestItem r) => r.id == req.id);
    });

    try {
      await _service.acceptFollowRequest(req.id);
      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          messenger: messenger,
          title: 'Request accepted',
          subtitle: '@${req.username} is now following you',
        );
        if (_isOwnProfile) {
          _loadFollowers(_effectiveUserId);
        }
      }
    } catch (e) {
      debugPrint('❌ [FollowersFollowingScreen] Accept request error: $e');
    }
  }

  Future<void> _rejectRequest(FollowRequestItem req) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() {
      _requests.removeWhere((FollowRequestItem r) => r.id == req.id);
    });

    try {
      await _service.rejectFollowRequest(req.id);
      if (mounted) {
        AppSnackBar.show(
          context,
          messenger: messenger,
          title: 'Request declined',
          subtitle: 'Follow request from @${req.username} removed',
        );
      }
    } catch (e) {
      debugPrint('❌ [FollowersFollowingScreen] Reject request error: $e');
    }
  }

  Future<void> _removeFollower(UserRelationItem user) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() {
      _followers.removeWhere((UserRelationItem u) => u.userId == user.userId);
    });

    try {
      await _service.removeFollower(user.userId);
      if (mounted) {
        AppSnackBar.show(
          context,
          messenger: messenger,
          title: '@${user.username} removed',
          subtitle: 'They are no longer in your followers list',
        );
      }
    } catch (e) {
      debugPrint('❌ [FollowersFollowingScreen] Remove follower error: $e');
    }
  }

  Future<void> _toggleFollowing(UserRelationItem user) async {
    if (_isMe(user)) {
      debugPrint('⚠️ [FollowersFollowingScreen] Cannot follow yourself.');
      return;
    }
    final ProfileProvider profileProvider = context.read<ProfileProvider>();
    final int folIndex = _following.indexWhere((UserRelationItem u) => u.userId == user.userId);
    final int folwIndex = _followers.indexWhere((UserRelationItem u) => u.userId == user.userId);
    final bool willFollow = !user.isFollowing;

    setState(() {
      if (folIndex != -1) {
        _following[folIndex] = user.copyWith(isFollowing: willFollow);
      }
      if (folwIndex != -1) {
        _followers[folwIndex] = user.copyWith(isFollowing: willFollow);
      }
    });

    try {
      if (willFollow) {
        await profileProvider.followUser(user.userId, username: user.username);
      } else {
        await profileProvider.unfollowUser(user.userId, username: user.username);
      }
    } catch (e) {
      debugPrint('❌ [FollowersFollowingScreen] Toggle following error: $e');
      if (mounted) {
        setState(() {
          if (folIndex != -1) _following[folIndex] = user; // revert
          if (folwIndex != -1) _followers[folwIndex] = user; // revert
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final String headerUsername = widget.username ??
        context.watch<ProfileProvider>().username;

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Header Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : context.themeBorder,
                          width: 1.1,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: context.themeIcon,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Center(
                      child: Text(
                        headerUsername.startsWith('@')
                            ? headerUsername
                            : '@$headerUsername',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: context.themeTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // ── Tab Bar (Followers · Following · Requests) ───────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: <Widget>[
                  // 1. Followers Tab
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedTab = 0);
                      _loadFollowers(_effectiveUserId);
                    },
                    child: Column(
                      children: <Widget>[
                        Text(
                          'Followers',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: _selectedTab == 0
                                ? context.themeTextPrimary
                                : context.themeTextMuted,
                            fontWeight: _selectedTab == 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 2.5,
                          width: 48,
                          color: _selectedTab == 0
                              ? (_selectedTab == 0 && !isDark
                                  ? const Color(0xFF12101A)
                                  : AppColors.gradientPink)
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.xl),

                  // 2. Following Tab
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedTab = 1);
                      _loadFollowing(_effectiveUserId);
                    },
                    child: Column(
                      children: <Widget>[
                        Text(
                          'Following',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: _selectedTab == 1
                                ? context.themeTextPrimary
                                : context.themeTextMuted,
                            fontWeight: _selectedTab == 1
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 2.5,
                          width: 48,
                          color: _selectedTab == 1
                              ? (_selectedTab == 1 && !isDark
                                  ? const Color(0xFF12101A)
                                  : AppColors.gradientPink)
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),

                  // 3. Requests Tab (Only for current user's profile)
                  if (_isOwnProfile) ...<Widget>[
                    const SizedBox(width: AppSpacing.xl),
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedTab = 2);
                        _loadRequests();
                      },
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                'Requests',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: _selectedTab == 2
                                      ? context.themeTextPrimary
                                      : context.themeTextMuted,
                                  fontWeight: _selectedTab == 2
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                              if (_requests.isNotEmpty) ...<Widget>[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.gradientPink,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_requests.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 2.5,
                            width: 58,
                            color: _selectedTab == 2
                                ? AppColors.gradientPink
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Divider(color: context.themeDivider, height: 1),

            const SizedBox(height: AppSpacing.md),

            // ── Search Input Field ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppTextField(
                controller: _searchController,
                hintText: _selectedTab == 2 ? 'Search requests' : 'Search',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.themeIconMuted,
                  size: 20,
                ),
                onChanged: (String val) => setState(() => _searchQuery = val),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Body List ───────────────────────────────────────────────────
            Expanded(
              child: _selectedTab == 2
                  ? _buildRequestsTab()
                  : _buildFollowersOrFollowingTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    final List<FollowRequestItem> filtered = _requests.where((FollowRequestItem req) {
      return _searchQuery.isEmpty ||
          req.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          req.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (_isLoadingRequests && _requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gradientPink),
      );
    }

    if (filtered.isEmpty) {
      return RefreshIndicator(
        color: AppColors.gradientPink,
        onRefresh: _loadRequests,
        child: LayoutBuilder(
          builder: (BuildContext ctx, BoxConstraints constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _requests.isEmpty
                          ? 'No pending follow requests.'
                          : 'No requests match your search.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.themeTextMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.gradientPink,
      onRefresh: _loadRequests,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        itemCount: filtered.length,
        separatorBuilder: (BuildContext _, int index) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (BuildContext context, int index) {
          final FollowRequestItem req = filtered[index];
          final String avatar = req.avatarUrl ?? '';

          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.themeCardBackground,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: context.themeBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => UserProfileScreen(
                          userId: req.userId,
                          username: req.username,
                          name: req.displayName,
                          avatarAsset: avatar.isNotEmpty ? avatar : AppImages.user1,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: <Widget>[
                      ClipOval(
                        child: (avatar.startsWith('http://') ||
                                avatar.startsWith('https://'))
                            ? Image.network(
                                avatar,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Image.asset(
                                  AppImages.user1,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                avatar.trim().startsWith('assets/')
                                    ? avatar.trim()
                                    : AppImages.user1,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Image.asset(
                                  AppImages.user1,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '@${req.username}',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: context.themeTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Wants to follow you',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.themeTextSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AppGradientButton(
                        text: 'Accept',
                        height: 36,
                        onPressed: () => _acceptRequest(req),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppOutlineButton(
                        text: 'Decline',
                        height: 36,
                        onPressed: () => _rejectRequest(req),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFollowersOrFollowingTab() {
    final bool isFollowersTab = _selectedTab == 0;
    final List<UserRelationItem> sourceList = isFollowersTab ? _followers : _following;
    final bool isLoading = isFollowersTab ? _isLoadingFollowers : _isLoadingFollowing;

    final List<UserRelationItem> filtered = sourceList.where((UserRelationItem user) {
      return _searchQuery.isEmpty ||
          user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return RefreshIndicator(
      color: AppColors.gradientPink,
      onRefresh: () => isFollowersTab
          ? _loadFollowers(_effectiveUserId)
          : _loadFollowing(_effectiveUserId),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        children: <Widget>[
          // Top Follow Requests Banner in Followers Tab for own profile
          if (isFollowersTab && _isOwnProfile && _requests.isNotEmpty) ...<Widget>[
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: context.themeCardBackground,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: context.themeBorder,
                ),
              ),
              child: Row(
                children: <Widget>[
                  ClipOval(
                    child: (_requests.first.avatarUrl ?? '').startsWith('http')
                        ? Image.network(
                            _requests.first.avatarUrl!,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Image.asset(
                              AppImages.user1,
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            (_requests.first.avatarUrl != null &&
                                    _requests.first.avatarUrl!.trim().startsWith('assets/'))
                                ? _requests.first.avatarUrl!.trim()
                                : AppImages.user1,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Image.asset(
                              AppImages.user1,
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '@${_requests.first.username}',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: context.themeTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Wants to follow you',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.themeTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppGradientButton(
                    text: 'Accept',
                    height: 30,
                    width: 68,
                    fontSize: 11,
                    onPressed: () => _acceptRequest(_requests.first),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppOutlineButton(
                    text: 'Decline',
                    height: 30,
                    width: 68,
                    fontSize: 11,
                    onPressed: () => _rejectRequest(_requests.first),
                  ),
                ],
              ),
            ),
          ],

          if (isLoading && sourceList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.gradientPink),
              ),
            )
          else if (filtered.isEmpty)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Text(
                  sourceList.isEmpty
                      ? (isFollowersTab
                          ? 'No followers yet.'
                          : 'Not following anyone yet.')
                      : 'No users found.',
                  style: TextStyle(
                    color: context.themeTextMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...filtered.map((UserRelationItem user) {
              final String avatar = user.avatarUrl ?? '';
              final String subtitle = user.pronouns != null && user.pronouns!.isNotEmpty
                  ? '${user.displayName} • ${user.pronouns}'
                  : user.displayName;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => UserProfileScreen(
                                userId: user.userId,
                                username: user.username,
                                name: user.displayName,
                                avatarAsset: avatar.isNotEmpty ? avatar : AppImages.user1,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: <Widget>[
                            ClipOval(
                              child: (avatar.startsWith('http://') ||
                                      avatar.startsWith('https://'))
                                  ? Image.network(
                                      avatar,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Image.asset(
                                        AppImages.user1,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.asset(
                                      avatar.trim().startsWith('assets/')
                                          ? avatar.trim()
                                          : AppImages.user1,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Image.asset(
                                        AppImages.user1,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '@${user.username}',
                                    style: AppTextStyles.titleSmall.copyWith(
                                      color: context.themeTextPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: context.themeTextSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    if (_isMe(user))
                      const SizedBox.shrink()
                    else if (isFollowersTab && _isOwnProfile)
                      AppOutlineButton(
                        text: 'Remove',
                        height: 32,
                        width: 78,
                        fontSize: 12,
                        onPressed: () => _removeFollower(user),
                      )
                    else
                      AppFollowButton(
                        isFollowing: user.isFollowing,
                        onTap: () => _toggleFollowing(user),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

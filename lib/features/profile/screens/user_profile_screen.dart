import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../auth/auth_provider.dart';
import '../../create_post/models/create_post_models.dart';
import '../../discover/models/discover_models.dart';
import '../../discover/services/discover_service.dart';
import '../../messages/models/message_models.dart';
import '../../messages/provider/messages_provider.dart';
import '../../messages/screens/chat_screen.dart';
import '../../profile_setup/models/community_model.dart';
import '../../profile_setup/models/profile_models.dart';
import '../widgets/profile_feed_tabs_widget.dart';
import '../widgets/profile_header_stats_widget.dart';
import '../widgets/profile_media_grid_widget.dart';
import '../widgets/user_profile_options_bottom_sheet.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    this.userId,
    this.username = 'rowankeeps',
    this.name = 'Rowan',
    this.avatarAsset = AppImages.user1,
    this.isPrivate = false,
    super.key,
  });

  final String? userId;
  final String username;
  final String name;
  final String avatarAsset;
  final bool isPrivate;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int _selectedTabIndex = 1; // Default: Reels
  bool _isRequested = false; // Default: Not requested (shows Follow initially)
  bool _isFollowing = false; // Default: Not following (shows Follow initially)
  bool _isLoading = false;
  bool _isStartingChat = false;
  String? _resolvedUserId;
  UserProfile? _profile;
  List<PostResponseModel> _authorPosts = <PostResponseModel>[];
  List<CommunityModel> _userCommunities = <CommunityModel>[];

  String? get _effectiveUserId {
    if (_profile?.id != null && _profile!.id.trim().isNotEmpty) {
      return _profile!.id.trim();
    }
    if (_resolvedUserId != null && _resolvedUserId!.trim().isNotEmpty) {
      return _resolvedUserId!.trim();
    }
    if (widget.userId != null && widget.userId!.trim().isNotEmpty) {
      return widget.userId!.trim();
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.userId != null && widget.userId!.trim().isNotEmpty) {
      _fetchUserProfile(widget.userId!.trim());
    } else if (widget.username.trim().isNotEmpty) {
      _resolveUserByUsername(widget.username);
    }
  }

  Future<void> _resolveUserByUsername(String rawUsername) async {
    final String cleanUsername = rawUsername.replaceAll('@', '').trim();
    if (cleanUsername.isEmpty) return;
    try {
      final DiscoverService discover =
          DiscoverService(context.read<ApiClient>());
      final MultiTabSearchResults results = await discover.search(
        query: cleanUsername,
        tab: 'people',
      );
      if (results.people.isNotEmpty) {
        final DiscoverPerson person = results.people.firstWhere(
          (DiscoverPerson p) =>
              p.username.replaceAll('@', '').toLowerCase() ==
              cleanUsername.toLowerCase(),
          orElse: () => results.people.first,
        );
        if (person.id != null && person.id!.trim().isNotEmpty && mounted) {
          setState(() {
            _resolvedUserId = person.id!.trim();
          });
          _fetchUserProfile(person.id!.trim());
        }
      }
    } catch (e) {
      debugPrint('⚠️ [UserProfile] Could not resolve username to id: $e');
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    setState(() {
      _isLoading = true;
    });

    final ApiClient client = context.read<ApiClient>();

    try {
      debugPrint('🚀 [UserProfile] Calling GET ${ApiEndpoints.user(userId)}');
      final dynamic data = await client.get(ApiEndpoints.user(userId));
      debugPrint('📥 [UserProfile] User profile response: $data');

      if (mounted && data is Map<String, dynamic>) {
        setState(() {
          _profile = UserProfile.fromJson(data);
        });
      }
    } catch (e) {
      debugPrint('❌ [UserProfile] Failed to fetch user profile: $e');
      if (widget.username.trim().isNotEmpty && _resolvedUserId == null) {
        _resolveUserByUsername(widget.username);
      }
    }

    try {
      final dynamic postsData =
          await client.get(ApiEndpoints.postsByAuthor(userId));
      if (mounted && postsData is List) {
        setState(() {
          _authorPosts = postsData
              .whereType<Map<String, dynamic>>()
              .map(PostResponseModel.fromJson)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('⚠️ [UserProfile] Could not fetch author posts: $e');
    }

    try {
      dynamic commData;
      try {
        commData = await client.get(ApiEndpoints.userCommunities(userId));
      } catch (e) {
        commData = await client.get(ApiEndpoints.userCommunitiesAlt(userId));
      }
      List<dynamic> rawList = <dynamic>[];
      if (commData is List) {
        rawList = commData;
      } else if (commData is Map<String, dynamic>) {
        if (commData['data'] is List) {
          rawList = commData['data'] as List<dynamic>;
        } else if (commData['communities'] is List) {
          rawList = commData['communities'] as List<dynamic>;
        }
      }
      final List<CommunityModel> comms = <CommunityModel>[];
      for (final dynamic item in rawList) {
        if (item is Map<String, dynamic>) {
          final Map<String, dynamic> m =
              (item['community'] is Map<String, dynamic>)
                  ? item['community'] as Map<String, dynamic>
                  : item;
          comms.add(CommunityModel.fromJson(m).copyWith(isJoined: true));
        } else if (item is String) {
          comms.add(CommunityModel(id: item, name: item, isJoined: true));
        }
      }
      if (mounted) {
        setState(() {
          _userCommunities = comms;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [UserProfile] Could not fetch user communities: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPrivateAccount =
        _profile?.isPrivate ?? (widget.isPrivate || widget.username.contains('kit.lumen'));
    final String currentUsername = _profile?.username ?? widget.username;
    final String currentName = _profile?.displayName ?? widget.name;
    final String currentAvatar = _profile?.avatarUrl ?? widget.avatarAsset;
    final String currentBio = _profile?.bio ??
        (isPrivateAccount
            ? 'Private account.'
            : (widget.userId != null ? '' : 'Documenting recovery, one honest video at a time.'));
    final String currentPronouns = _profile?.formattedPronouns ??
        (isPrivateAccount ? 'he / him' : '');

    final AuthProvider auth = context.watch<AuthProvider>();
    final String? myId = auth.userId;
    final String? myName = auth.user?.displayName;
    final bool isOwnProfile = (myId != null &&
            myId.isNotEmpty &&
            _effectiveUserId == myId) ||
        (myName != null &&
            myName.isNotEmpty &&
            widget.username.replaceAll('@', '').toLowerCase() ==
                myName.replaceAll('@', '').toLowerCase());

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Header Bar (Back chevron < + Username + 3-dots Menu) ────
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
                        color: context.isDarkMode
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.isDarkMode
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            currentUsername.startsWith('@')
                                ? currentUsername
                                : '@$currentUsername',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: context.themeTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          if (isPrivateAccount) ...<Widget>[
                            const SizedBox(width: 6),
                            SvgPicture.asset(
                              AppIcons.password,
                              width: 14,
                              height: 14,
                              colorFilter: ColorFilter.mode(
                                context.themeIconMuted,
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // 3-dots Options Menu -> Opens UserProfileOptionsBottomSheet
                  GestureDetector(
                    onTap: () {
                      UserProfileOptionsBottomSheet.show(
                        context,
                        username: currentUsername,
                        userId: _effectiveUserId,
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.isDarkMode
                              ? Colors.white.withValues(alpha: 0.12)
                              : context.themeBorder,
                          width: 1.1,
                        ),
                      ),
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: context.themeIcon,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable Profile Body ─────────────────────────────────────
            Expanded(
              child: _isLoading && _profile == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gradientPink,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      children: <Widget>[
                        // Profile Header & Stats Widget
                        ProfileHeaderStatsWidget(
                          avatarAsset: currentAvatar,
                          name: currentName,
                          bio: currentBio,
                          postsCount: _profile?.postsCount != null
                              ? '${_profile!.postsCount}'
                              : '${_authorPosts.length}',
                          followersCount: _profile?.followersCount != null
                              ? '${_profile!.followersCount}'
                              : '0',
                          followingCount: _profile?.followingCount != null
                              ? '${_profile!.followingCount}'
                              : '0',
                          onFollowersTap: () {},
                          onFollowingTap: () {},
                          pronounsPill: currentPronouns,
                          pronounsList: _profile?.pronouns ??
                              (isPrivateAccount
                                  ? const <String>[]
                                  : const <String>[]),
                          identityList: const <String>[],
                          interestsList:
                              _profile?.interests ?? const <String>[],
                          communitiesList: _userCommunities,
                    actionButtons: isOwnProfile
                        ? Row(
                            children: <Widget>[
                              Expanded(
                                child: AppOutlineButton(
                                  text: 'Edit Profile',
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ],
                          )
                        : Row(
                      children: <Widget>[
                        Expanded(
                          child: isPrivateAccount
                              ? (_isRequested
                                  ? GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isRequested = false;
                                        });
                                      },
                                      child: Container(
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: context.themeCardBackground,
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.card),
                                          border: Border.all(
                                            color: AppColors.gradientCyan,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            const Icon(
                                              Icons.access_time_rounded,
                                              color: AppColors.gradientCyan,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Requested',
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                color: AppColors.gradientCyan,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : AppGradientButton(
                                      text: 'Follow',
                                      onPressed: () {
                                        setState(() {
                                          _isRequested = true;
                                        });
                                      },
                                    ))
                              : (_isFollowing
                                  ? AppOutlineButton(
                                      text: 'Following',
                                      onPressed: () {
                                        setState(() {
                                          _isFollowing = false;
                                        });
                                      },
                                    )
                                  : AppGradientButton(
                                      text: 'Follow',
                                      onPressed: () {
                                        setState(() {
                                          _isFollowing = true;
                                        });
                                      },
                                    )),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppOutlineButton(
                            text: _isStartingChat ? 'Loading...' : 'Message',
                            onPressed: _isStartingChat
                                ? () {}
                                : () async {
                                    final ScaffoldMessengerState messenger =
                                        ScaffoldMessenger.of(context);
                                    final NavigatorState navigator =
                                        Navigator.of(context);
                                    final MessagesProvider provider =
                                        context.read<MessagesProvider>();
                                    final ApiClient apiClient =
                                        context.read<ApiClient>();
                                    final AuthProvider auth =
                                        context.read<AuthProvider>();

                                    setState(() {
                                      _isStartingChat = true;
                                    });

                                    try {
                                      String? targetId = _effectiveUserId;

                                      // If targetId is still not resolved, attempt resolution now
                                      if (targetId == null || targetId.isEmpty) {
                                        final String cleanUsername = widget
                                            .username
                                            .replaceAll('@', '')
                                            .trim();
                                        if (cleanUsername.isNotEmpty) {
                                          try {
                                            final DiscoverService discover =
                                                DiscoverService(apiClient);
                                            final MultiTabSearchResults results =
                                                await discover.search(
                                              query: cleanUsername,
                                              tab: 'people',
                                            );
                                            if (results.people.isNotEmpty) {
                                              final DiscoverPerson person =
                                                  results.people.firstWhere(
                                                (DiscoverPerson p) =>
                                                    p.username
                                                        .replaceAll('@', '')
                                                        .toLowerCase() ==
                                                    cleanUsername.toLowerCase(),
                                                orElse: () =>
                                                    results.people.first,
                                              );
                                              targetId = person.id;
                                              if (mounted && targetId != null) {
                                                setState(() {
                                                  _resolvedUserId = targetId;
                                                });
                                              }
                                            }
                                          } catch (_) {}
                                        }
                                      }

                                      if (targetId == null || targetId.trim().isEmpty) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Cannot start conversation: User ID not found.',
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        return;
                                      }

                                      final String cleanTargetId =
                                          targetId.trim();
                                      final String? myId = auth.userId;
                                      if (myId != null &&
                                          cleanTargetId == myId) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'You cannot start a conversation with yourself.',
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        return;
                                      }

                                      ConversationModel? conv;
                                      String? errorText;
                                      try {
                                        conv = await provider
                                            .startConversation(cleanTargetId);
                                      } on ApiException catch (e) {
                                        errorText = e.message.isNotEmpty
                                            ? e.message
                                            : 'This user is not accepting messages from you.';
                                      } catch (e) {
                                        errorText =
                                            'Unable to start conversation right now.';
                                      }

                                      if (conv == null) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              errorText ??
                                                  'This user is not accepting messages from you.',
                                            ),
                                            duration:
                                                const Duration(seconds: 3),
                                            backgroundColor:
                                                Colors.redAccent.shade700,
                                          ),
                                        );
                                        return;
                                      }

                                      final String currentUsername = (_profile?.username != null &&
                                              _profile!.username!.trim().isNotEmpty)
                                          ? _profile!.username!.trim()
                                          : widget.username.replaceAll('@', '').trim();
                                      final String currentName = (_profile?.displayName != null &&
                                              _profile!.displayName!.trim().isNotEmpty)
                                          ? _profile!.displayName!.trim()
                                          : widget.name.trim();
                                      final String currentAvatar = (_profile?.avatarUrl != null &&
                                              _profile!.avatarUrl!.trim().isNotEmpty)
                                          ? _profile!.avatarUrl!.trim()
                                          : widget.avatarAsset.trim();

                                      final ConversationModel enrichedConv = conv.copyWith(
                                        username: currentUsername.isNotEmpty && currentUsername != 'User'
                                            ? currentUsername
                                            : conv.username,
                                        displayName: currentName.isNotEmpty ? currentName : conv.displayName,
                                        avatarUrl: currentAvatar.startsWith('http') ? currentAvatar : conv.avatarUrl,
                                        avatarAsset: currentAvatar.isNotEmpty ? currentAvatar : conv.avatarAsset,
                                        participantId: cleanTargetId,
                                      );

                                      provider.updateConversation(enrichedConv);

                                      navigator.push<void>(
                                        MaterialPageRoute<void>(
                                          builder: (_) => ChatScreen(
                                            conversation: enrichedConv,
                                          ),
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _isStartingChat = false;
                                        });
                                      }
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── If Private Account -> Show Centered Private Placeholder (Image 1) ──
                  if (isPrivateAccount) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxl),
                    Center(
                      child: Column(
                        children: <Widget>[
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: context.themeCardBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: context.themeBorder,
                              ),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                AppIcons.password,
                                width: 26,
                                height: 26,
                                colorFilter: ColorFilter.mode(
                                  context.themeIcon,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'This account is private',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: context.themeTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              "Kit approves followers one by one. You'll get a notification if your request is accepted.",
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.themeTextSecondary,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ]

                  // ── If Public Account -> Show Feed Tabs & Media Grid ───────
                  else ...<Widget>[
                    ProfileFeedTabsWidget(
                      selectedIndex: _selectedTabIndex,
                      isOwnProfile: false,
                      onTabSelected: (int index) {
                        setState(() => _selectedTabIndex = index);
                      },
                    ),

                    // Tab 0: Posts Feed Cards
                    if (_selectedTabIndex == 0) ...<Widget>[
                      if (_authorPosts.isNotEmpty) ...<Widget>[
                        for (final PostResponseModel post in _authorPosts) ...<Widget>[
                          Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: context.themeCardBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: context.themeBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    ClipOval(
                                      child: currentAvatar.startsWith('http')
                                          ? Image.network(
                                              currentAvatar,
                                              width: 32,
                                              height: 32,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  const Icon(Icons.person, size: 32),
                                            )
                                          : Image.asset(
                                              currentAvatar,
                                              width: 32,
                                              height: 32,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          currentUsername.startsWith('@')
                                              ? currentUsername
                                              : '@$currentUsername',
                                          style: AppTextStyles.titleSmall.copyWith(
                                            color: context.themeTextPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (post.createdAt != null)
                                          Text(
                                            post.createdAt!,
                                            style: AppTextStyles.caption.copyWith(
                                              color: context.themeTextMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (post.body.isNotEmpty) ...<Widget>[
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    post.body,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: context.themeTextPrimary,
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ] else ...<Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                          child: Center(
                            child: Text(
                              'No posts yet.',
                              style: TextStyle(
                                color: context.themeTextMuted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],

                    // Tab 1: Reels Grid
                    if (_selectedTabIndex == 1)
                      const ProfileMediaGridWidget(showPlayCounts: true),

                    // Tab 2: Saved Grid
                    if (_selectedTabIndex == 2)
                      const ProfileMediaGridWidget(showPlayCounts: false),

                    // Tab 3: Liked Grid
                    if (_selectedTabIndex == 3)
                      const ProfileMediaGridWidget(showPlayCounts: false),
                  ],

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

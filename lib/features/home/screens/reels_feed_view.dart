import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../profile/provider/profile_provider.dart';
import '../../profile_setup/models/community_model.dart';
import '../../profile_setup/provider/profile_setup_provider.dart';
import '../models/reel_item_model.dart';
import '../provider/home_feed_provider.dart';
import '../services/reel_video_preloader.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/filter_communities_bottom_sheet.dart';
import '../widgets/guest_action_modal_dialog.dart';
import '../widgets/home_empty_state_view.dart';
import '../widgets/reel_feed_card.dart';
import '../widgets/delete_reel_bottom_sheet.dart';
import '../widgets/safety_bottom_sheet.dart';
import '../widgets/send_to_bottom_sheet.dart';
import '../widgets/share_this_post_bottom_sheet.dart';

/// TikTok / Instagram Reels-style smooth page snapping physics.
/// Uses a critically-damped spring (mass: 0.35, stiffness: 400.0, ratio: 1.1)
/// ensuring lightning-fast, crisp snaps with ZERO oscillation and ZERO sticking midway.
class ReelScrollPhysics extends PageScrollPhysics {
  const ReelScrollPhysics({super.parent});

  @override
  ReelScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ReelScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 0.35,
        stiffness: 400.0,
        ratio: 1.1,
      );
}

class ReelsFeedView extends StatefulWidget {
  const ReelsFeedView({
    this.onGuestActionTriggered,
    this.initialPage = 0,
    this.customReels,
    this.hasBottomBar = true,
    super.key,
  });

  final VoidCallback? onGuestActionTriggered;
  final int initialPage;
  final List<ReelItemModel>? customReels;
  final bool hasBottomBar;

  @override
  State<ReelsFeedView> createState() => _ReelsFeedViewState();
}

class _ReelsFeedViewState extends State<ReelsFeedView> {
  late final PageController _pageController;
  late int _activePage;
  List<ReelItemModel> _localReels = <ReelItemModel>[];

  // Guest: show signup popup after 3 reels
  int _guestReelsWatched = 0;
  bool _guestPopupShown = false;

  @override
  void initState() {
    super.initState();
    _activePage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
    if (widget.customReels != null) {
      _localReels = List<ReelItemModel>.from(widget.customReels!);
      // Restore feed visibility for standalone/custom reel viewers.
      // When the home feed's ReelFeedCard.didPushNext fires (e.g. user opened
      // profile), it sets isFeedVisible=false. If the user then opens a custom
      // reel player, that flag is still false → _canPlayAudio = false → no audio.
      ReelVideoPreloader.instance.setFeedVisible(true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final HomeFeedProvider provider = context.read<HomeFeedProvider>();
        final List<ReelItemModel> reels =
            widget.customReels != null ? _localReels : provider.reels;
        if (reels.isNotEmpty) {
          ReelVideoPreloader.instance.preloadSurrounding(reels, _activePage);
          if (_activePage < reels.length) {
            provider.recordView(reels[_activePage].id);
          }
        }
      }
    });
  }

  @override
  void didUpdateWidget(ReelsFeedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.customReels != null && widget.customReels != oldWidget.customReels) {
      _localReels = List<ReelItemModel>.from(widget.customReels!);
    }
  }

  @override
  void deactivate() {
    ReelVideoPreloader.instance.pauseAll();
    // Use markFeedInvisible() instead of setFeedVisible(false) — the latter
    // triggers async pauseAll()/muteAll() platform-channel calls that complete
    // after deactivation and throw "deactivated widget ancestor" FlutterError.
    if (widget.customReels != null) {
      ReelVideoPreloader.instance.markFeedInvisible();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _pageController.dispose();
    ReelVideoPreloader.instance.pauseAll();
    super.dispose();
  }

  void _showFilterCommunitiesSheet(
    BuildContext context,
    HomeFeedProvider provider,
  ) {
    List<CommunityModel> availableComms = const <CommunityModel>[];
    try {
      final List<CommunityModel> userComms =
          context.read<ProfileProvider>().userCommunities;
      final List<CommunityModel> allComms =
          context.read<ProfileSetupProvider>().allCommunities;

      final Map<String, CommunityModel> commMap = <String, CommunityModel>{};
      for (final CommunityModel c in userComms) {
        commMap[c.id] = c;
      }
      for (final CommunityModel c in allComms) {
        commMap.putIfAbsent(c.id, () => c);
      }
      availableComms = commMap.values.toList();
    } catch (_) {}

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FilterCommunitiesBottomSheet(
          selectedCommunity: provider.selectedCommunityFilter,
          communities: availableComms,
          onApply: (String community, String? communityId) {
            provider.setSelectedCommunityFilter(
              community,
              communityId: communityId,
            );
          },
        );
      },
    );
  }

  void _showCommentsSheet(
    BuildContext context,
    String postId,
    int totalComments, {
    String? postAuthorId,
    bool allowComments = true,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CommentsBottomSheet(
          postId: postId,
          postAuthorId: postAuthorId,
          totalComments: totalComments,
          allowComments: allowComments,
          onCommentAdded: () {
            context.read<HomeFeedProvider>().incrementCommentCount(postId);
          },
        );
      },
    );
  }

  void _showShareSheet(BuildContext context, ReelItemModel reel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ShareThisPostBottomSheet(
          reel: reel,
          onOpenMoreSendTo: () {
            Navigator.pop(context);
            _showSendToSheet(context, reel);
          },
          onOpenReportSafety: () {
            Navigator.pop(context);
            _showSafetySheet(reel);
          },
        );
      },
    );
  }

  void _showSendToSheet(BuildContext context, [ReelItemModel? reel]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SendToBottomSheet(reel: reel);
      },
    );
  }

  Future<void> _showDeleteSheet(ReelItemModel reel) async {
    final bool? deleted = await DeleteReelBottomSheet.show(context, reel: reel);
    if (deleted == true && mounted) {
      setState(() {
        _localReels.removeWhere((ReelItemModel r) => r.id == reel.id);
      });
      final List<ReelItemModel> currentReels =
          widget.customReels != null ? _localReels : context.read<HomeFeedProvider>().reels;
      if (currentReels.isEmpty && widget.customReels != null) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _showSafetySheet(ReelItemModel reel) async {
    await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafetyBottomSheet(
          username: reel.username,
          postId: reel.id,
          authorId: reel.authorId ?? reel.username,
          communityId: reel.communityId,
          isReel: true,
          isCreator: false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final HomeFeedProvider provider = context.watch<HomeFeedProvider>();
    final List<ReelItemModel> reels =
        widget.customReels != null ? _localReels : provider.reels;
    final double topInset = MediaQuery.of(context).padding.top + 50;

    if (provider.isLoadingFeed && reels.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gradientPink),
      );
    }

    if (reels.isEmpty) {
      final bool isCommunityTab = provider.activeTopTab == TopTab.communities;
      return RefreshIndicator(
        color: AppColors.gradientPink,
        backgroundColor: const Color(0xFF1E1E2E),
        edgeOffset: topInset,
        onRefresh: () => provider.loadFeed(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: Stack(
                  children: <Widget>[
                    HomeEmptyStateView(
                      title: isCommunityTab &&
                              provider.selectedCommunityFilter !=
                                  'All Communities'
                          ? 'No videos in ${provider.selectedCommunityFilter}'
                          : null,
                      subtitle: isCommunityTab &&
                              provider.selectedCommunityFilter !=
                                  'All Communities'
                          ? 'There are no videos in this community yet. Explore other communities or be the first to post!'
                          : null,
                      buttonText: isCommunityTab ? 'Explore Communities' : null,
                      onOpenExplore: () {
                        if (isCommunityTab) {
                          _showFilterCommunitiesSheet(context, provider);
                        } else {
                          provider.loadFeed(force: true);
                        }
                      },
                    ),
                    if (isCommunityTab)
                      Positioned(
                        top: topInset + 10,
                        left: 16,
                        child: GestureDetector(
                          onTap: () =>
                              _showFilterCommunitiesSheet(context, provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.secondaryGradientButton,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.gradientCyan
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(
                                  Icons.groups_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  provider.selectedCommunityFilter,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.gradientPink,
      backgroundColor: const Color(0xFF1E1E2E),
      displacement: 60,
      edgeOffset: topInset,
      onRefresh: () async {
        await provider.loadFeed();
        if (mounted && reels.isNotEmpty) {
          ReelVideoPreloader.instance.preloadSurrounding(reels, _activePage);
        }
      },
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: const ReelScrollPhysics(),
        itemCount: reels.length,
        onPageChanged: (int index) {
          setState(() => _activePage = index);
          ReelVideoPreloader.instance.preloadSurrounding(reels, index);
          if (index < reels.length) {
            provider.recordView(reels[index].id);
          }
          // Guest: show signup popup after watching 3 reels
          if (provider.isGuest && widget.customReels == null && !_guestPopupShown) {
            _guestReelsWatched++;
            if (_guestReelsWatched >= 3) {
              _guestPopupShown = true;
              Future<void>.delayed(const Duration(milliseconds: 400), () {
                if (!mounted) return;
                ReelVideoPreloader.instance.pauseAll();
                GuestActionModalDialog.show(
                  // ignore: use_build_context_synchronously
                  context,
                  title: 'Join QueerLoop',
                  subtitle:
                      'Create a free account to get your personalized For You feed, like, comment and connect with the community.',
                  iconData: Icons.favorite_border_rounded,
                );
              });
            }
          }
        },
        itemBuilder: (context, index) {
          final ReelItemModel item = reels[index];
          final ProfileProvider profileProvider = context.watch<ProfileProvider>();
          final bool isAuthorFollowed = profileProvider.isFollowingUser(
            userId: item.authorId,
            username: item.username,
          ) || item.isFollowing;

          final bool isVisuallyActive = (widget.customReels != null)
              ? (index == _activePage)
              : (index == _activePage &&
                  provider.bottomNavIndex == 0 &&
                  provider.activeSubMode == SubMode.reels);

          final bool isItemLiked = provider.isPostLiked(item.id) || item.isLiked;
          final bool isItemSaved = provider.isPostSaved(item.id) || item.isSaved;

          return ReelFeedCard(
            key: ValueKey<String>(item.id),
            reel: item.copyWith(
              isFollowing: isAuthorFollowed,
              isLiked: isItemLiked,
              isSaved: isItemSaved,
            ),
            isActive: isVisuallyActive,
            hasBottomBar: widget.hasBottomBar,
            showCommunityFilterTag: provider.activeTopTab == TopTab.communities,
            selectedCommunity: provider.selectedCommunityFilter,
            onLikeToggle: () {
              if (provider.isGuest) {
                widget.onGuestActionTriggered?.call();
              } else {
                final bool currentlyLiked =
                    provider.isPostLiked(item.id) || item.isLiked;
                final bool newLiked = !currentlyLiked;
                final int newCount = newLiked
                    ? item.likesCount + 1
                    : (item.likesCount > 0 ? item.likesCount - 1 : 0);

                if (widget.customReels != null) {
                  final int idx = _localReels.indexWhere((r) => r.id == item.id);
                  if (idx != -1) {
                    setState(() {
                      _localReels[idx] = _localReels[idx].copyWith(
                        isLiked: newLiked,
                        likesCount: newCount,
                      );
                    });
                  }
                }
                try {
                  context.read<ProfileProvider>().updateLikedReel(
                    item.id,
                    isLiked: newLiked,
                    likesCount: newCount,
                    fallbackReel: item.copyWith(isLiked: newLiked, likesCount: newCount),
                  );
                } catch (_) {}
                // Pass the original item (not pre-toggled) so toggleLikeReel
                // can correctly compute the direction by negating item.isLiked.
                provider.toggleLikeReel(
                  item.id,
                  fallbackReel: item,
                );
              }
            },
            onSaveToggle: () {
              if (provider.isGuest) {
                widget.onGuestActionTriggered?.call();
              } else {
                final bool currentlySaved =
                    provider.isPostSaved(item.id) || item.isSaved;
                final bool newSaved = !currentlySaved;

                if (widget.customReels != null) {
                  final int idx = _localReels.indexWhere((r) => r.id == item.id);
                  if (idx != -1) {
                    setState(() {
                      _localReels[idx] = _localReels[idx].copyWith(isSaved: newSaved);
                    });
                  }
                }
                try {
                  context.read<ProfileProvider>().updateSavedReel(
                    item.id,
                    isSaved: newSaved,
                    fallbackReel: item.copyWith(isSaved: newSaved),
                  );
                } catch (_) {}
                // Pass the original item (not pre-toggled) so toggleSaveReel
                // can correctly compute the direction by negating item.isSaved.
                provider.toggleSaveReel(
                  item.id,
                  fallbackReel: item,
                );
              }
            },
            onFollowToggle: () async {
              if (provider.isGuest) {
                widget.onGuestActionTriggered?.call();
              } else {
                final String? targetId = item.authorId;
                final bool willFollow = !isAuthorFollowed;
                if (targetId != null && targetId.isNotEmpty) {
                  provider.setAuthorFollowStatus(
                    authorId: targetId,
                    username: item.username,
                    isFollowing: willFollow,
                  );
                  try {
                    if (willFollow) {
                      await profileProvider.followUser(targetId, username: item.username);
                    } else {
                      await profileProvider.unfollowUser(targetId, username: item.username);
                    }
                  } catch (e) {
                    provider.setAuthorFollowStatus(
                      authorId: targetId,
                      username: item.username,
                      isFollowing: !willFollow,
                    );
                  }
                } else {
                  provider.toggleFollowReel(item.id);
                }
              }
            },
            onOpenComments: () {
              if (provider.isGuest) {
                widget.onGuestActionTriggered?.call();
              } else {
                _showCommentsSheet(
                  context,
                  item.id,
                  item.commentsCount,
                  postAuthorId: item.authorId,
                  allowComments: item.allowComments,
                );
              }
            },
            onOpenShare: () {
              if (provider.isGuest) {
                widget.onGuestActionTriggered?.call();
              } else {
                _showShareSheet(context, item);
              }
            },
            isCustomView: widget.customReels != null,
            onDelete: () => _showDeleteSheet(item),
            onOpenSafety: () => _showSafetySheet(item),
            onOpenFilterCommunities: () =>
                _showFilterCommunitiesSheet(context, provider),
          );
        },
      ),
    );
  }
}

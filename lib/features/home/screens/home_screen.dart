import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../provider/home_feed_provider.dart';
import '../widgets/guest_action_modal_dialog.dart';
import '../widgets/guest_join_overlay_card.dart';
import '../widgets/home_bottom_nav_bar.dart';
import '../widgets/home_top_header_tabs.dart';
import '../../create_post/widgets/create_post_type_bottom_sheet.dart';
import '../../discover/screens/discover_screen.dart';
import '../../messages/screens/messages_screen.dart';
import 'discover_tab_screen.dart';
import 'guest_profile_tab_screen.dart';
import 'posts_feed_view.dart';
import 'profile_tab_screen.dart';
import 'reels_feed_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    this.isGuest = false,
    super.key,
  });

  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    // HomeFeedProvider is always registered at the app root (app.dart)
    return _HomeScreenContent(isGuest: isGuest);
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent({required this.isGuest});

  final bool isGuest;

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> {
  bool _showGuestOverlayCard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeFeedProvider>().setGuestMode(widget.isGuest);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _HomeScreenContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isGuest != widget.isGuest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<HomeFeedProvider>().setGuestMode(widget.isGuest);
        }
      });
    }
  }

  void _triggerGuestAction(BuildContext context, HomeFeedProvider provider) {
    setState(() {
      _showGuestOverlayCard = true;
    });
  }

  void _handleTopTabTap(
      BuildContext context, HomeFeedProvider provider, TopTab tab) {
    if (provider.isGuest &&
        (tab == TopTab.following || tab == TopTab.communities)) {
      GuestActionModalDialog.show(
        context,
        title: 'Sign up to browse community',
        subtitle:
            'Create a free account to see communities, react and join the communities. Browsing stays free forever.',
        iconData: Icons.chat_bubble_outline_rounded,
      );
      return;
    }
    provider.setTopTab(tab);
  }

  void _handleBottomNavTap(
      BuildContext context, HomeFeedProvider provider, int index) {
    if (provider.isGuest) {
      if (index == 2) {
        // Center Lock button tap in Guest mode -> triggers centered overlay card with dark background
        _triggerGuestAction(context, provider);
        return;
      } else if (index == 3) {
        // Messages button tap in Guest mode -> triggers modal dialog
        GuestActionModalDialog.show(
          context,
          title: 'Sign up to send messages',
          subtitle:
              'Create a free account to DM people, react and join the conversation. Browsing stays free forever.',
          iconData: Icons.chat_bubble_outline_rounded,
        );
        return;
      }
    }
    if (!provider.isGuest && index == 2) {
      CreatePostTypeBottomSheet.show(context);
      return;
    }
    provider.setBottomNavIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final HomeFeedProvider provider = context.watch<HomeFeedProvider>();
    final int navIndex = provider.bottomNavIndex;

    Widget bodyContent;

    if (provider.isGuest) {
      // ── Guest Mode Navigation ─────────────────────────────────────────────
      if (navIndex == 1) {
        bodyContent = const DiscoverTabScreen(isGuest: true);
      } else if (navIndex == 4) {
        bodyContent = const GuestProfileTabScreen();
      } else {
        bodyContent = Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (provider.activeSubMode == SubMode.reels)
              ReelsFeedView(
                onGuestActionTriggered: () {
                  _triggerGuestAction(context, provider);
                },
              )
            else
              PostsFeedView(
                onGuestActionTriggered: () {
                  _triggerGuestAction(context, provider);
                },
              ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: HomeTopHeaderTabs(
                activeTab: provider.activeTopTab,
                activeSubMode: provider.activeSubMode,
                isGuest: true,
                onTabSelected: (tab) =>
                    _handleTopTabTap(context, provider, tab),
                onSubModeSelected: (mode) => provider.setSubMode(mode),
              ),
            ),
            // Centered Guest Action Overlay Card with Dark Dimmed Background
            if (_showGuestOverlayCard)
              Positioned.fill(
                child: Stack(
                  children: <Widget>[
                    // Dark Dimmed Background Scrim
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showGuestOverlayCard = false;
                        });
                      },
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.65),
                      ),
                    ),

                    // Centered Guest Join Overlay Card
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GuestJoinOverlayCard(
                          onClose: () {
                            setState(() {
                              _showGuestOverlayCard = false;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      }
    } else {
      // ── Logged-In User Navigation ─────────────────────────────────────────
      if (navIndex == 1) {
        bodyContent = const DiscoverScreen();
      } else if (navIndex == 2) {
        bodyContent = const _PlaceholderTabScreen(title: 'Create Post Screen');
      } else if (navIndex == 3) {
        bodyContent = const MessagesScreen();
      } else if (navIndex == 4) {
        bodyContent = const ProfileTabScreen();
      } else {
        bodyContent = Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (provider.activeSubMode == SubMode.reels)
              const ReelsFeedView()
            else
              const PostsFeedView(),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: HomeTopHeaderTabs(
                activeTab: provider.activeTopTab,
                activeSubMode: provider.activeSubMode,
                isGuest: false,
                onTabSelected: (tab) =>
                    _handleTopTabTap(context, provider, tab),
                onSubModeSelected: (mode) => provider.setSubMode(mode),
              ),
            ),
          ],
        );
      }
    }

    return Scaffold(
      backgroundColor: context.themeBackground,
      // extendBody: true lets the body (reels/posts) fill the full screen
      // edge-to-edge behind the floating bottomNavigationBar.
      extendBody: true,
      // Scaffold's own layout always positions bottomNavigationBar correctly
      // at the very bottom from the first frame — no Stack/Positioned needed.
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: navIndex,
        isGuest: provider.isGuest,
        onTap: (index) => _handleBottomNavTap(context, provider, index),
      ),
      body: bodyContent,
    );
  }
}

class _PlaceholderTabScreen extends StatelessWidget {
  const _PlaceholderTabScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming Soon',
              style: TextStyle(
                color: AppColors.gradientCyan,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

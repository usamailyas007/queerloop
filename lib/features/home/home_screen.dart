
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import 'provider/home_feed_provider.dart';
import 'screens/discover_tab_screen.dart';
import 'screens/messages_tab_screen.dart';
import 'screens/posts_feed_view.dart';
import 'screens/profile_tab_screen.dart';
import 'screens/reels_feed_view.dart';
import 'widgets/home_bottom_nav_bar.dart';
import 'widgets/home_top_header_tabs.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeFeedProvider>(
      create: (_) => HomeFeedProvider(),
      child: const _HomeScreenBody(),
    );
  }
}

class _HomeScreenBody extends StatelessWidget {
  const _HomeScreenBody();

  @override
  Widget build(BuildContext context) {
    final HomeFeedProvider provider = context.watch<HomeFeedProvider>();
    final int navIndex = provider.bottomNavIndex;
    final SubMode subMode = provider.activeSubMode;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Stack(
          children: <Widget>[
            IndexedStack(
              index: navIndex == 2 ? 0 : navIndex,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    subMode == SubMode.reels
                        ? const ReelsFeedView()
                        : const PostsFeedView(),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: HomeTopHeaderTabs(
                            activeTab: provider.activeTopTab,
                            activeSubMode: provider.activeSubMode,
                            onTabSelected: (TopTab tab) =>
                                provider.setTopTab(tab),
                            onSubModeSelected: (SubMode mode) =>
                                provider.setSubMode(mode),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const DiscoverTabScreen(),
                const SizedBox.shrink(),
                const MessagesTabScreen(),
                const ProfileTabScreen(),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: HomeBottomNavBar(
                currentIndex: navIndex,
                onTap: (int index) {
                  if (index == 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Create Post / Reel option tapped'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } else {
                    provider.setBottomNavIndex(index);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

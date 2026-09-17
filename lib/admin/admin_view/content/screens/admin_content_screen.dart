import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../analytics/provider/analytics_provider.dart';
import '../models/content_post.dart';
import '../provider/content_provider.dart';
import '../widgets/content_post_grid.dart';
import '../widgets/content_trending_section.dart';
import 'admin_post_detail_dialog.dart';

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ContentProvider>().loadInitial();
      }
    });
  }

  void _onError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      context.read<ContentProvider>().clearError();
    });
  }

  Future<void> _toggle(ContentPost post) async {
    final ContentProvider provider = context.read<ContentProvider>();
    final bool ok = post.isHidden
        ? await provider.restorePost(post.id)
        : await provider.hidePost(post.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(post.isHidden ? 'Post restored.' : 'Post hidden.'),
        ));
      // Analytics/Dashboard read the same "content hidden"/"posts" numbers —
      // re-pull them now so switching tabs shows current data instead of
      // whatever was cached from the last visit.
      unawaited(context.read<AnalyticsProvider>().refresh());
    }
  }

  Future<void> _delete(ContentPost post) async {
    final ContentProvider provider = context.read<ContentProvider>();
    final bool ok = await provider.deletePost(post.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Post deleted.')));
      unawaited(context.read<AnalyticsProvider>().refresh());
    }
  }

  void _showDetail(ContentPost post) => showPostDetailDialog(context, post);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Consumer<ContentProvider>(
          builder: (_, ContentProvider provider, _) {
            if (provider.error != null && provider.posts.isNotEmpty) {
              _onError(provider.error!);
            }
            return RefreshIndicator(
              color: AppColors.adminPink,
              backgroundColor: AppColors.adminSurface,
              onRefresh: provider.refresh,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Text(
                        'Content',
                        style: TextStyle(color: AppColors.adminTextPrimary, fontWeight: FontWeight.w700, fontSize: 24),
                      ),
                      const SizedBox(width: 10),
                      if (provider.posts.isNotEmpty)
                        Text(
                          '${provider.posts.length} posts',
                          style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ContentPostGrid(provider: provider, onView: _showDetail, onToggle: _toggle, onDelete: _delete),
                  const SizedBox(height: AppSpacing.xl),
                  ContentTrendingSection(provider: provider, onView: _showDetail),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

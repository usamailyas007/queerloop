import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../models/content_post.dart';
import '../provider/content_provider.dart';
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
    }
  }

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
                        style: TextStyle(
                          color: AppColors.adminTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (provider.total > 0)
                        Text(
                          '${provider.total} posts',
                          style: const TextStyle(
                            color: AppColors.adminTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PostGrid(
                      provider: provider,
                      onView: _showDetail,
                      onToggle: _toggle),
                  const SizedBox(height: AppSpacing.xl),
                  _TrendingSection(provider: provider, onView: _showDetail),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDetail(ContentPost post) => showPostDetailDialog(context, post);
}

// ── Post grid ───────────────────────────────────────────────────────────────

class _PostGrid extends StatelessWidget {
  const _PostGrid({
    required this.provider,
    required this.onView,
    required this.onToggle,
  });

  final ContentProvider provider;
  final ValueChanged<ContentPost> onView;
  final ValueChanged<ContentPost> onToggle;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.adminPink,
            ),
          ),
        ),
      );
    }
    if (provider.error != null && provider.posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                provider.error!,
                style: const TextStyle(
                  color: AppColors.adminTextSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: 120,
                child: AppOutlineButton(
                  text: 'Retry',
                  height: 38,
                  onPressed: provider.refresh,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (provider.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Text(
            'No posts yet.',
            style: TextStyle(color: AppColors.adminTextMuted, fontSize: 13),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.58,
      ),
      itemBuilder: (_, int i) {
        final ContentPost post = provider.posts[i];
        return _ContentCard(
          post: post,
          busy: provider.isMutating(post.id),
          onView: () => onView(post),
          onToggle: () => onToggle(post),
        );
      },
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.post,
    required this.busy,
    required this.onView,
    required this.onToggle,
  });

  final ContentPost post;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
        post.isHidden ? AppColors.adminPink : AppColors.adminTeal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _Thumb(post: post),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _pill(post.statusLabel, statusColor),
                ),
                if (post.reportCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _pill('⚑ ${post.reportCount}', AppColors.adminOrange),
                  ),
                if (post.type == ContentPostType.video)
                  const Center(
                    child: Icon(Icons.play_circle_fill_rounded,
                        color: Colors.white70, size: 34),
                  ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.remove_red_eye_outlined,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        NumberFormat.compact().format(post.viewCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${post.author.handle} · ${post.type.label}',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.adminTextSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            Expanded(child: _MiniButton(label: 'View', onTap: onView)),
            const SizedBox(width: 4),
            Expanded(
              child: busy
                  ? const SizedBox(
                      height: 25,
                      child: Center(
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.adminPink,
                          ),
                        ),
                      ),
                    )
                  : _MiniButton(
                      label: post.isHidden ? 'Restore' : 'Hide',
                      danger: !post.isHidden,
                      onTap: onToggle,
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      );
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.post});

  final ContentPost post;

  @override
  Widget build(BuildContext context) {
    final String? ref = post.primaryMediaRef;
    final MediaAsset? asset = ref == null
        ? null
        : context.select<ContentProvider, MediaAsset?>(
            (ContentProvider p) => p.media(ref),
          );

    final Widget placeholder = Container(
      color: AppColors.adminSurfaceAlt,
      alignment: Alignment.center,
      child: Icon(
        post.type == ContentPostType.video
            ? Icons.videocam_outlined
            : post.type == ContentPostType.text
                ? Icons.notes_rounded
                : Icons.image_outlined,
        color: AppColors.adminTextMuted,
        size: 22,
      ),
    );

    final String? url = asset?.posterUrl;
    if (url == null) {
      return placeholder;
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

// ── Trending ────────────────────────────────────────────────────────────────

class _TrendingSection extends StatelessWidget {
  const _TrendingSection({required this.provider, required this.onView});

  final ContentProvider provider;
  final ValueChanged<ContentPost> onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.local_fire_department_rounded,
                  size: 16, color: AppColors.adminOrange),
              SizedBox(width: 6),
              Text(
                'Trending',
                style: TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (provider.isLoadingTrending && provider.trending.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.adminPink,
                  ),
                ),
              ),
            )
          else if (provider.trending.isEmpty)
            const Text(
              'Nothing trending right now.',
              style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
            )
          else
            Builder(
              builder: (_) {
                final List<ContentPost> items =
                    provider.trending.take(6).toList();
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (_, int i) => _TrendingCard(
                    post: items[i],
                    rank: i + 1,
                    onTap: () => onView(items[i]),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({
    required this.post,
    required this.rank,
    required this.onTap,
  });

  final ContentPost post;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _Thumb(post: post),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.remove_red_eye_outlined,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          NumberFormat.compact().format(post.viewCount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${post.author.handle} · ${post.type.label}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.adminTextSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: danger
              ? AppColors.adminPink.withValues(alpha: 0.14)
              : AppColors.adminSurfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: danger
                ? AppColors.adminPink.withValues(alpha: 0.4)
                : AppColors.adminButtonBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: danger ? AppColors.adminPink : AppColors.adminTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

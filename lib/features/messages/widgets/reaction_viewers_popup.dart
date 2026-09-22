import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_images.dart';
import '../models/message_models.dart';

/// Shows a small floating popup listing who reacted (grouped by emoji).
/// Call [ReactionViewersPopup.show] with the tap's global position.
class ReactionViewersPopup {
  ReactionViewersPopup._();

  static Future<void> show(
    BuildContext context, {
    required List<MessageReactionModel> reactions,
    required Offset tapPosition,
    required String myUserId,
    required VoidCallback onRemoveReaction,
  }) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (BuildContext ctx) => _ReactionPopupWidget(
        reactions: reactions,
        tapPosition: tapPosition,
        myUserId: myUserId,
        onRemoveReaction: onRemoveReaction,
      ),
    );
  }
}

class _ReactionPopupWidget extends StatefulWidget {
  const _ReactionPopupWidget({
    required this.reactions,
    required this.tapPosition,
    required this.myUserId,
    required this.onRemoveReaction,
  });

  final List<MessageReactionModel> reactions;
  final Offset tapPosition;
  final String myUserId;
  final VoidCallback onRemoveReaction;

  @override
  State<_ReactionPopupWidget> createState() => _ReactionPopupWidgetState();
}

class _ReactionPopupWidgetState extends State<_ReactionPopupWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  String? _selectedEmoji;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();

    // Group reactions by emoji and find first emoji
    final Map<String, List<MessageReactionModel>> grouped = _groupByEmoji();
    if (grouped.isNotEmpty) {
      _selectedEmoji = grouped.keys.first;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Map<String, List<MessageReactionModel>> _groupByEmoji() {
    final Map<String, List<MessageReactionModel>> map =
        <String, List<MessageReactionModel>>{};
    for (final MessageReactionModel r in widget.reactions) {
      if (r.emoji.trim().isNotEmpty) {
        map.putIfAbsent(r.emoji, () => <MessageReactionModel>[]).add(r);
      }
    }
    return map;
  }

  bool get _iReacted => widget.reactions
      .any((MessageReactionModel r) => r.userId == widget.myUserId);

  @override
  Widget build(BuildContext context) {
    final Map<String, List<MessageReactionModel>> grouped = _groupByEmoji();
    if (grouped.isEmpty) return const SizedBox.shrink();

    final List<String> emojiTabs = grouped.keys.toList();
    _selectedEmoji ??= emojiTabs.first;
    final List<MessageReactionModel> displayList =
        grouped[_selectedEmoji] ?? <MessageReactionModel>[];

    final Size screen = MediaQuery.of(context).size;
    const double popupWidth = 260;
    const double popupMaxHeight = 260;

    // Anchor the popup above or below the tap point
    double left = widget.tapPosition.dx - popupWidth / 2;
    left = left.clamp(12.0, screen.width - popupWidth - 12.0);

    double top = widget.tapPosition.dy - popupMaxHeight - 12;
    if (top < 60) top = widget.tapPosition.dy + 24;

    return Stack(
      children: <Widget>[
        // Dismiss overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),

        // Popup card
        Positioned(
          left: left,
          top: top,
          child: ScaleTransition(
            scale: _scaleAnim,
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: popupWidth,
                constraints: const BoxConstraints(maxHeight: popupMaxHeight),
                decoration: BoxDecoration(
                  color: context.themeCardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.themeBorder),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // ── Emoji Tab Row ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: context.themeBorder,
                            width: 0.8,
                          ),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          // "All" tab
                          _EmojiTab(
                            emoji: 'All',
                            count: widget.reactions.length,
                            isSelected: _selectedEmoji == 'All',
                            onTap: () => setState(() => _selectedEmoji = 'All'),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          ...emojiTabs.map((String e) => Padding(
                                padding:
                                    const EdgeInsets.only(left: AppSpacing.xs),
                                child: _EmojiTab(
                                  emoji: e,
                                  count: grouped[e]!.length,
                                  isSelected: _selectedEmoji == e,
                                  onTap: () =>
                                      setState(() => _selectedEmoji = e),
                                ),
                              )),
                        ],
                      ),
                    ),

                    // ── Reactor List ───────────────────────────────────
                    Flexible(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        shrinkWrap: true,
                        itemCount: _selectedEmoji == 'All'
                            ? widget.reactions.length
                            : displayList.length,
                        itemBuilder: (BuildContext ctx, int i) {
                          final MessageReactionModel r = _selectedEmoji == 'All'
                              ? widget.reactions[i]
                              : displayList[i];
                          final bool isMe = r.userId == widget.myUserId;
                          return _ReactorTile(
                            reaction: r,
                            isMe: isMe,
                          );
                        },
                      ),
                    ),

                    // ── Remove My Reaction Button ──────────────────────
                    if (_iReacted) ...<Widget>[
                      Divider(
                        height: 1,
                        color: context.themeBorder,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onRemoveReaction();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Remove my reaction',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.gradientCyan,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmojiTab extends StatelessWidget {
  const _EmojiTab({
    required this.emoji,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gradientCyan.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.gradientCyan : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              emoji == 'All' ? '🔢' : emoji,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(width: 3),
            Text(
              '$count',
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? AppColors.gradientCyan
                    : context.themeTextMuted,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactorTile extends StatelessWidget {
  const _ReactorTile({
    required this.reaction,
    required this.isMe,
  });

  final MessageReactionModel reaction;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final String displayName = isMe
        ? 'You'
        : (reaction.username?.isNotEmpty == true
            ? reaction.username!
            : 'User');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          // Avatar placeholder
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.themeChipBackground,
              border: Border.all(color: context.themeBorder),
            ),
            child: ClipOval(
              child: Image.asset(
                AppImages.user1,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: context.themeIconMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: isMe
                    ? AppColors.gradientCyan
                    : context.themeTextPrimary,
                fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            reaction.emoji,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

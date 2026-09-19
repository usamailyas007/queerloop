import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/auth_provider.dart';
import '../../discover/models/discover_models.dart';
import '../../discover/services/discover_service.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../models/message_models.dart';
import '../provider/messages_provider.dart';
import 'chat_screen.dart';

class DiscoverPeopleScreen extends StatefulWidget {
  const DiscoverPeopleScreen({this.initialQuery, super.key});

  final String? initialQuery;

  @override
  State<DiscoverPeopleScreen> createState() => _DiscoverPeopleScreenState();
}

class _DiscoverPeopleScreenState extends State<DiscoverPeopleScreen> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  bool _isSearching = false;
  bool _isLoadingSuggestions = true;
  String _currentQuery = '';
  String? _startingChatUserId;

  List<DiscoverPerson> _searchResults = <DiscoverPerson>[];
  List<DiscoverCreator> _suggestedPeople = <DiscoverCreator>[];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _currentQuery = widget.initialQuery?.trim() ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_currentQuery.isNotEmpty) {
          _performSearch(_currentQuery);
        }
        _loadSuggestedPeople();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestedPeople() async {
    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      final DiscoverService discover =
          DiscoverService(context.read<ApiClient>());
      List<DiscoverCreator> creators =
          await discover.getCreators(type: 'to_watch');
      if (creators.isEmpty) {
        creators = await discover.getCreators(type: 'new');
      }

      if (mounted) {
        setState(() {
          _suggestedPeople = creators;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [DiscoverPeopleScreen] Error loading suggestions: $e');
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final String trimmed = query.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _currentQuery = '';
        _searchResults = <DiscoverPerson>[];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _currentQuery = trimmed;
      _isSearching = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(trimmed);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    try {
      final DiscoverService discover =
          DiscoverService(context.read<ApiClient>());
      final MultiTabSearchResults results =
          await discover.search(query: query, tab: 'people');

      if (mounted && _currentQuery == query) {
        setState(() {
          _searchResults = results.people;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [DiscoverPeopleScreen] Search error: $e');
      if (mounted && _currentQuery == query) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _handleStartMessage({
    required String targetId,
    required String username,
    required String avatarAsset,
    String? displayName,
  }) async {
    final ApiClient client = context.read<ApiClient>();
    final AuthProvider auth = context.read<AuthProvider>();
    final MessagesProvider provider = context.read<MessagesProvider>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);

    String resolvedTargetId = targetId.trim();

    setState(() {
      _startingChatUserId = targetId.isNotEmpty ? targetId : username;
    });

    try {
      // 1. If targetId is empty, dynamically resolve user UUID by username
      if (resolvedTargetId.isEmpty) {
        final String cleanUsername = username.replaceAll('@', '').trim();
        if (cleanUsername.isNotEmpty) {
          try {
            final DiscoverService discover = DiscoverService(client);
            final MultiTabSearchResults searchRes = await discover.search(
              query: cleanUsername,
              tab: 'people',
            );
            if (searchRes.people.isNotEmpty) {
              final DiscoverPerson matched = searchRes.people.firstWhere(
                (DiscoverPerson p) =>
                    p.username.replaceAll('@', '').toLowerCase() ==
                    cleanUsername.toLowerCase(),
                orElse: () => searchRes.people.first,
              );
              if (matched.id != null && matched.id!.trim().isNotEmpty) {
                resolvedTargetId = matched.id!.trim();
              }
            }
          } catch (e) {
            debugPrint('⚠️ [DiscoverPeopleScreen] Could not resolve user ID: $e');
          }
        }
      }

      // 2. If still empty, do not proceed or send empty request
      if (resolvedTargetId.isEmpty) {
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Cannot start conversation: User ID not found.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // 3. Self-messaging check
      final String? myId = auth.userId;
      if (myId != null && resolvedTargetId == myId) {
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('You cannot start a conversation with yourself.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final ConversationModel? conv =
          await provider.startConversation(resolvedTargetId);

      if (conv != null && mounted) {
        navigator.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ChangeNotifierProvider<MessagesProvider>.value(
              value: provider,
              child: ChatScreen(conversation: conv),
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              e.message.isNotEmpty
                  ? e.message
                  : 'This user is not accepting messages from you.',
            ),
            backgroundColor: Colors.redAccent.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Unable to start conversation right now.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _startingChatUserId = null;
        });
      }
    }
  }

  Widget _buildAvatar(String avatarUrl) {
    if (avatarUrl.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          avatarUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: 44,
            height: 44,
            color: Colors.white10,
            child: const Icon(Icons.person, size: 24, color: Colors.white70),
          ),
        ),
      );
    }

    return ClipOval(
      child: Image.asset(
        avatarUrl.isNotEmpty ? avatarUrl : AppImages.user1,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 44,
          height: 44,
          color: Colors.white10,
          child: const Icon(Icons.person, size: 24, color: Colors.white70),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isQueryActive = _currentQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Top Header Bar (Back button + Title "Discover people") ─────────
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
                    child: Text(
                      'Discover people',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Search Input Field ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppTextField(
                controller: _searchController,
                hintText: 'Search by name or @username',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.themeIconMuted,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          size: 18,
                          color: context.themeIconMuted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                onChanged: _onSearchChanged,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Section Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                isQueryActive ? 'SEARCH RESULTS' : 'SUGGESTED PEOPLE',
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.themeTextMuted,
                  letterSpacing: 1.2,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── List Body (Real-time Results OR Suggestions) ─────────────────
            Expanded(
              child: isQueryActive
                  ? _buildSearchResultsView()
                  : _buildSuggestionsView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsView() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.gradientPink,
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.person_search_rounded,
                size: 56,
                color: context.themeIconMuted,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No people found',
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.themeTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No users match "$_currentQuery". Try searching by exact @username or full name.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.themeTextSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _searchResults.length,
      itemBuilder: (BuildContext context, int index) {
        final DiscoverPerson person = _searchResults[index];
        final String rawId = person.id ?? '';
        final String cleanUsername = person.username.startsWith('@')
            ? person.username
            : '@${person.username}';
        final String displayName = (person.displayName != null &&
                person.displayName!.trim().isNotEmpty)
            ? person.displayName!
            : person.username.replaceAll('@', '');
        final bool isStartingChat = _startingChatUserId == rawId ||
            (_startingChatUserId != null && _startingChatUserId == person.username);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.themeBorder.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              // Avatar & User Info (Tap -> Open UserProfileScreen)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => UserProfileScreen(
                          userId: rawId.isNotEmpty ? rawId : null,
                          username: person.username.replaceAll('@', ''),
                          name: displayName,
                          avatarAsset: person.avatarAsset,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: <Widget>[
                      _buildAvatar(person.avatarAsset),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleSmall.copyWith(
                                color: context.themeTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cleanUsername,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.themeTextSecondary,
                                fontSize: 12,
                              ),
                            ),
                            if (person.followers.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(
                                person.followers,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.gradientCyan,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Message Action Button
              AppGradientButton(
                text: isStartingChat ? 'Loading...' : 'Message',
                height: 34,
                width: 88,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onPressed: () => _handleStartMessage(
                  targetId: rawId,
                  username: person.username,
                  avatarAsset: person.avatarAsset,
                  displayName: displayName,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsView() {
    if (_isLoadingSuggestions) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.gradientPink,
        ),
      );
    }

    if (_suggestedPeople.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.people_outline_rounded,
                size: 52,
                color: context.themeIconMuted,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Search for people',
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.themeTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Type a name or username above to find people to chat with.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.themeTextSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _suggestedPeople.length,
      itemBuilder: (BuildContext context, int index) {
        final DiscoverCreator creator = _suggestedPeople[index];
        final String rawId = creator.id ?? '';
        final String cleanUsername = creator.username.startsWith('@')
            ? creator.username
            : '@${creator.username}';
        final String displayName = (creator.displayName != null &&
                creator.displayName!.trim().isNotEmpty)
            ? creator.displayName!
            : creator.username.replaceAll('@', '');
        final bool isStartingChat = _startingChatUserId == rawId ||
            (_startingChatUserId != null && _startingChatUserId == creator.username);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.themeBorder.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              // Avatar & User Info
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => UserProfileScreen(
                          userId: rawId.isNotEmpty ? rawId : null,
                          username: creator.username.replaceAll('@', ''),
                          name: displayName,
                          avatarAsset: creator.avatarAsset,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: <Widget>[
                      _buildAvatar(creator.avatarAsset),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleSmall.copyWith(
                                color: context.themeTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cleanUsername,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.themeTextSecondary,
                                fontSize: 12,
                              ),
                            ),
                            if (creator.followerCount != null &&
                                creator.followerCount! > 0) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(
                                creator.followerCount! > 1000
                                    ? '${(creator.followerCount! / 1000).toStringAsFixed(1)}K followers'
                                    : '${creator.followerCount} followers',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.gradientCyan,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Message Action Button
              AppGradientButton(
                text: isStartingChat ? 'Loading...' : 'Message',
                height: 34,
                width: 88,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onPressed: () => _handleStartMessage(
                  targetId: rawId,
                  username: creator.username,
                  avatarAsset: creator.avatarAsset,
                  displayName: displayName,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

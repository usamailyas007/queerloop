// Owns the admin Content tab: the paginated post grid, trending strip, media
// URL resolution, and hide/restore.
// Mirrors features/auth/auth_provider.dart conventions (isBusy/error, selective
// notifyListeners()).

import 'package:flutter/foundation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../content_service.dart';
import '../models/content_post.dart';

class ContentProvider extends ChangeNotifier {
  ContentProvider({required ApiClient client, ContentService? service})
      : _service = service ?? ContentService(client);

  final ContentService _service;

  static const int pageSize = 6; // one row of 6 in the grid

  // ── Posts ─────────────────────────────────────────────────────────────────

  List<ContentPost> _posts = <ContentPost>[];
  int _total = 0;
  int _page = 1;
  bool _isLoading = false;
  String? _error;
  bool _loadedOnce = false;
  final Set<String> _mutatingIds = <String>{};

  List<ContentPost> get posts => List<ContentPost>.unmodifiable(_posts);
  int get total => _total;
  int get page => _page;
  int get pageCount => _total == 0 ? 1 : ((_total + pageSize - 1) ~/ pageSize);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _loadedOnce && !_isLoading && _posts.isEmpty;
  bool get canPrev => _page > 1 && !_isLoading;
  bool get canNext => _page < pageCount && !_isLoading;
  bool isMutating(String id) => _mutatingIds.contains(id);

  // ── Trending ──────────────────────────────────────────────────────────────

  List<ContentPost> _trending = <ContentPost>[];
  bool _isLoadingTrending = false;
  List<ContentPost> get trending => List<ContentPost>.unmodifiable(_trending);
  bool get isLoadingTrending => _isLoadingTrending;

  // ── Media cache ───────────────────────────────────────────────────────────

  final Map<String, MediaAsset?> _media = <String, MediaAsset?>{};

  /// Resolved media for a ref (null while loading or if it failed).
  MediaAsset? media(String? ref) => ref == null ? null : _media[ref];

  // ── Loading ───────────────────────────────────────────────────────────────

  Future<void> loadInitial() async {
    if (_loadedOnce || _isLoading) {
      return;
    }
    await Future.wait(<Future<void>>[_loadPage(1), _loadTrending()]);
  }

  Future<void> refresh() =>
      Future.wait(<Future<void>>[_loadPage(_page), _loadTrending()]);

  Future<void> goToPage(int target) {
    final int p = target.clamp(1, pageCount);
    if (p == _page || _isLoading) {
      return Future<void>.value();
    }
    return _loadPage(p);
  }

  Future<void> nextPage() => goToPage(_page + 1);
  Future<void> prevPage() => goToPage(_page - 1);

  Future<void> _loadPage(int page) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final ContentPostsPage result =
          await _service.fetchPosts(page: page, limit: pageSize);
      _posts = result.items;
      _total = result.total;
      _page = result.page < 1 ? page : result.page;
      _error = null;
      _resolveMediaFor(_posts);
    } on ApiException catch (failure) {
      _posts = <ContentPost>[];
      _error = failure.message;
    } catch (_) {
      _posts = <ContentPost>[];
      _error = 'Unable to load content. Please try again.';
    } finally {
      _isLoading = false;
      _loadedOnce = true;
      notifyListeners();
    }
  }

  Future<void> _loadTrending() async {
    _isLoadingTrending = true;
    notifyListeners();
    try {
      _trending = await _service.fetchTrending();
      _resolveMediaFor(_trending);
    } on ApiException catch (_) {
      // Non-critical — the main grid still renders.
    } finally {
      _isLoadingTrending = false;
      notifyListeners();
    }
  }

  /// Resolve the first media ref of each post, in parallel, into the cache.
  void _resolveMediaFor(List<ContentPost> posts) {
    final Set<String> refs = <String>{
      for (final ContentPost p in posts)
        if (p.primaryMediaRef != null) p.primaryMediaRef!,
    }..removeWhere(_media.containsKey);
    if (refs.isEmpty) {
      return;
    }
    for (final String ref in refs) {
      _media[ref] = null; // mark as in-flight
    }
    Future.wait(refs.map((String ref) async {
      _media[ref] = await _service.fetchMedia(ref);
    })).whenComplete(notifyListeners);
  }

  /// Fetch one post by id and pre-resolve its media, so any screen (e.g. the
  /// report detail) can hand it straight to [showPostDetailDialog]. Returns
  /// null if the post can't be loaded.
  Future<ContentPost?> loadPostById(String id) async {
    final ContentPost? post = await _service.fetchPostById(id);
    if (post == null) {
      return null;
    }
    final String? ref = post.primaryMediaRef;
    if (ref != null && _media[ref] == null) {
      _media[ref] = await _service.fetchMedia(ref);
      notifyListeners();
    }
    return post;
  }

  /// Resolve an arbitrary media ref (used by the detail view). Idempotent.
  Future<MediaAsset?> ensureMedia(String ref) async {
    if (_media.containsKey(ref) && _media[ref] != null) {
      return _media[ref];
    }
    final MediaAsset? asset = await _service.fetchMedia(ref);
    _media[ref] = asset;
    notifyListeners();
    return asset;
  }

  // ── Hide / restore ────────────────────────────────────────────────────────

  Future<bool> hidePost(String id) => _mutate(id, hide: true);

  Future<bool> restorePost(String id) => _mutate(id, hide: false);

  Future<bool> _mutate(String id, {required bool hide}) async {
    if (_mutatingIds.contains(id)) {
      return false;
    }
    _mutatingIds.add(id);
    notifyListeners();
    try {
      if (hide) {
        await _service.hidePost(id);
      } else {
        await _service.restorePost(id);
      }
      // Re-pull the current page so status badges reflect the server.
      await _loadPage(_page);
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Could not update this post. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _mutatingIds.remove(id);
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}

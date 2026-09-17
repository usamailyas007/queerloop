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
  // Only successful lookups are cached. A failed fetch is *not* remembered as
  // a permanent miss — without this, one transient `/media/:id` failure (e.g.
  // a slow CDN edge, a hiccup right as a post is hidden) would mark the ref as
  // "already tried" forever, and no later refetch/hide/restore/reload would
  // ever retry it, leaving that thumbnail blank for the rest of the session.

  final Map<String, MediaAsset> _media = <String, MediaAsset>{};
  final Set<String> _mediaInFlight = <String>{};

  /// Resolved media for a ref (null while loading, unresolved, or if the last
  /// attempt failed — the next call to resolve it will retry).
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
  /// Skips refs already resolved or currently being fetched — but, unlike a
  /// plain `containsKey` check, a ref whose last attempt failed is retried.
  void _resolveMediaFor(List<ContentPost> posts) {
    final Set<String> refs = <String>{
      for (final ContentPost p in posts)
        if (p.primaryMediaRef != null) p.primaryMediaRef!,
    }
      ..removeWhere(_media.containsKey)
      ..removeWhere(_mediaInFlight.contains);
    if (refs.isEmpty) {
      return;
    }
    _mediaInFlight.addAll(refs);
    Future.wait(refs.map((String ref) async {
      final MediaAsset? asset = await _service.fetchMedia(ref);
      if (asset != null) {
        _media[ref] = asset;
      }
      _mediaInFlight.remove(ref);
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
    if (ref != null && !_media.containsKey(ref)) {
      await ensureMedia(ref);
    }
    return post;
  }

  /// Resolve an arbitrary media ref (used by the detail view). Idempotent —
  /// safe to call again after a previous failure, which retries it.
  Future<MediaAsset?> ensureMedia(String ref) async {
    final MediaAsset? cached = _media[ref];
    if (cached != null) {
      return cached;
    }
    if (_mediaInFlight.contains(ref)) {
      return null;
    }
    _mediaInFlight.add(ref);
    final MediaAsset? asset = await _service.fetchMedia(ref);
    _mediaInFlight.remove(ref);
    if (asset != null) {
      _media[ref] = asset;
    }
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

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<bool> deletePost(String id) async {
    if (_mutatingIds.contains(id)) {
      return false;
    }
    _mutatingIds.add(id);
    notifyListeners();
    try {
      await _service.deletePost(id);
      // Re-pull the current page so the grid reflects the server.
      await _loadPage(_page);
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Could not delete this post. Please try again.';
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

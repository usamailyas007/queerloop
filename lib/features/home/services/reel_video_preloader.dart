import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

import '../models/reel_item_model.dart';
import '../../../core/utils/video_size_logger.dart';
import 'video_cache_service.dart';

/// Custom cache manager for reel videos.
/// Stores up to 200 video files on disk for up to 7 days.
class ReelVideoCacheManager extends CacheManager with ImageCacheManager {
  static const String key = 'reelVideoCache';

  static final ReelVideoCacheManager _instance = ReelVideoCacheManager._();
  factory ReelVideoCacheManager() => _instance;

  ReelVideoCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 200,
          ),
        );
}

/// Centralized manager that pre-buffers and caches VideoPlayerControllers.
///
/// Strategy:
///  1. On first view → download video to disk via [ReelVideoCacheManager]
///  2. On subsequent views → play directly from disk (zero network cost)
///  3. Keep controllers alive for ±5 positions around the current index
///     so short back/forward scrolls never trigger a re-init.
class ReelVideoPreloader {
  ReelVideoPreloader._();
  static final ReelVideoPreloader instance = ReelVideoPreloader._();

  final Map<String, VideoPlayerController> _controllers =
      <String, VideoPlayerController>{};
  final Set<String> _initializing = <String>{};
  final Set<String> _activeReelIds = <String>{};
  final Map<String, String> _diskCachePathMap = <String, String>{};
  final Set<String> _cachingUrls = <String>{};
  bool _isFeedVisible = true;

  /// Whether the feed is currently active and visible to the user
  bool get isFeedVisible => _isFeedVisible;

  /// Set whether the feed is visible on screen. If false, pauses and mutes all controllers.
  void setFeedVisible(bool visible) {
    _isFeedVisible = visible;
    if (!visible) {
      pauseAll();
      muteAll();
    }
  }

  /// Only flip the feed-visible flag — without triggering async pause/mute calls.
  /// Use this inside dispose()/deactivate() where async platform-channel ops
  /// would look up deactivated ancestors and throw a FlutterError.
  void markFeedInvisible() {
    _isFeedVisible = false;
  }

  /// Mark a reel as actively viewed on screen so its controller is never disposed
  void markActive(String id) {
    _activeReelIds.add(id);
  }

  /// Mark a reel as no longer actively viewed
  void markInactive(String id) {
    _activeReelIds.remove(id);
  }

  /// Check if a controller is still alive and registered in preloader
  bool isAlive(VideoPlayerController? controller) {
    if (controller == null) return false;
    return _controllers.containsValue(controller);
  }

  /// Returns an already-created controller without waiting.
  VideoPlayerController? getExisting(String id) => _controllers[id];

  /// Asynchronously caches video file to disk in background so subsequent loads are instant.
  Future<void> _cacheVideoInBackground(String videoUrl) async {
    if (videoUrl.isEmpty || _cachingUrls.contains(videoUrl)) return;
    if (videoUrl.contains('.m3u8')) return;
    if (_diskCachePathMap.containsKey(videoUrl)) {
      final File f = File(_diskCachePathMap[videoUrl]!);
      if (f.existsSync()) return;
    }

    try {
      _cachingUrls.add(videoUrl);
      final FileInfo? info =
          await ReelVideoCacheManager().getFileFromCache(videoUrl);
      if (info != null && info.file.existsSync()) {
        _diskCachePathMap[videoUrl] = info.file.path;
        return;
      }

      final File downloaded =
          await ReelVideoCacheManager().getSingleFile(videoUrl);
      _diskCachePathMap[videoUrl] = downloaded.path;
      debugPrint('📥 [ReelCache] Background cached to disk: $videoUrl');
    } catch (e) {
      debugPrint('⚠️ [ReelCache] Background caching error: $e');
    } finally {
      _cachingUrls.remove(videoUrl);
    }
  }

  // ── Internal: resolve to cached file or network URL ──────────────────────

  /// Resolves video source via VideoCacheService (checks local disk cache first,
  /// then adaptive streaming URL based on internet speed).
  Future<ResolvedVideoSource> _resolveSource(ReelItemModel reel) async {
    return VideoCacheService.instance.resolveVideoSource(reel);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Get an existing controller or create and initialize a new one.
  Future<VideoPlayerController?> getOrCreate(ReelItemModel reel) async {
    final String key = reel.id;

    if (_controllers.containsKey(key)) {
      final VideoPlayerController existing = _controllers[key]!;
      if (!existing.value.isInitialized && !_initializing.contains(key)) {
        try {
          _initializing.add(key);
          await existing.initialize();
          if (!_isFeedVisible || !_activeReelIds.contains(reel.id)) {
            existing.pause();
            existing.setVolume(0);
          }
          VideoSizeLogger.logFeedVideoSize(
            id: reel.id,
            title: reel.username.isNotEmpty ? '@${reel.username}' : reel.caption,
            videoUrl: reel.videoUrl,
            assetPath: reel.videoAsset.isNotEmpty ? reel.videoAsset : null,
            controller: existing,
            stage: 'Feed Reel Active',
          );
        } catch (e) {
          debugPrint(
              '⚠️ [ReelVideoPreloader] Error re-initializing controller $key: $e');
        } finally {
          _initializing.remove(key);
        }
      }
      return existing;
    }

    if (_initializing.contains(key)) {
      // Wait up to 5s for a concurrent init to complete
      int waitMs = 0;
      while (_initializing.contains(key) && waitMs < 5000) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        waitMs += 100;
      }
      return _controllers[key];
    }

    VideoPlayerController? controller;
    try {
      _initializing.add(key);

      final ResolvedVideoSource source = await _resolveSource(reel);
      bool initializedSuccessfully = false;

      if (source.type != VideoSourceType.none) {
        try {
          switch (source.type) {
            case VideoSourceType.file:
              controller = VideoPlayerController.file(source.file!);
            case VideoSourceType.network:
              controller = VideoPlayerController.networkUrl(
                source.uri!,
                formatHint: source.formatHint,
              );
            case VideoSourceType.asset:
              controller = VideoPlayerController.asset(source.assetPath!);
            case VideoSourceType.none:
              break;
          }

          if (controller != null) {
            _controllers[key] = controller;
            await controller.initialize();
            initializedSuccessfully = true;
          }
        } catch (initErr) {
          debugPrint('⚠️ [ReelVideoPreloader] Primary source init failed for $key: $initErr');
          _controllers.remove(key);
          try {
            await controller?.dispose();
          } catch (_) {}
          controller = null;
        }
      }

      // If primary source was an explicit asset specified by the reel
      if (!initializedSuccessfully && reel.videoAsset.isNotEmpty) {
        try {
          controller = VideoPlayerController.asset(reel.videoAsset);
          _controllers[key] = controller;
          await controller.initialize();
          initializedSuccessfully = true;
          debugPrint('🎬 [ReelVideoPreloader] Asset loaded for $key: ${reel.videoAsset}');
        } catch (assetErr) {
          debugPrint('⚠️ [ReelVideoPreloader] Asset failed for $key: $assetErr');
          _controllers.remove(key);
          try {
            await controller?.dispose();
          } catch (_) {}
          controller = null;
        }
      }

      if (controller != null && initializedSuccessfully) {
        controller.setLooping(true);
        if (_isFeedVisible && _activeReelIds.contains(reel.id)) {
          controller.setVolume(1.0);
        } else {
          controller.pause();
          controller.setVolume(0);
        }
        VideoSizeLogger.logFeedVideoSize(
          id: reel.id,
          title: reel.username.isNotEmpty ? '@${reel.username}' : reel.caption,
          videoUrl: reel.videoUrl,
          file: source.file,
          assetPath: source.assetPath ??
              (reel.videoAsset.isNotEmpty ? reel.videoAsset : null),
          controller: controller,
          stage: source.isLocalCache
              ? 'Local Disk Cache (Offline/Instant)'
              : 'Feed Reel Loaded (Adaptive)',
        );
        return controller;
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ [ReelVideoPreloader] Failed to initialize reel $key: $e');
      _controllers.remove(key);
      try {
        await controller?.dispose();
      } catch (_) {}
      return null;
    } finally {
      _initializing.remove(key);
    }
  }

  /// Preload adjacent reels and dispose distant ones.
  ///
  /// Priority: current reel first → next 2 → prev 1.
  /// All background-preloaded controllers are paused + muted immediately.
  void preloadSurrounding(List<ReelItemModel> reels, int currentIndex) {
    if (reels.isEmpty || !_isFeedVisible) return;

    // 1. Background disk-cache for smooth future loads (non-blocking)
    for (int i = currentIndex - 2; i <= currentIndex + 4; i++) {
      if (i >= 0 && i < reels.length && i != currentIndex) {
        final String? url = reels[i].videoUrl;
        if (url != null && url.isNotEmpty) {
          _cacheVideoInBackground(url);
        }
      }
    }

    // 2. Preload next 2 reels — init controller but keep paused + muted
    for (int i = currentIndex + 1;
        i <= currentIndex + 2 && i < reels.length;
        i++) {
      final ReelItemModel reel = reels[i];
      getOrCreate(reel).then((VideoPlayerController? c) {
        if (c != null && c.value.isInitialized) {
          try {
            c.pause();
            c.setVolume(0);
          } catch (_) {}
        }
      });
    }

    // 3. Preload prev 1 reel — init but keep paused + muted
    if (currentIndex - 1 >= 0) {
      final ReelItemModel reel = reels[currentIndex - 1];
      getOrCreate(reel).then((VideoPlayerController? c) {
        if (c != null && c.value.isInitialized) {
          try {
            c.pause();
            c.setVolume(0);
          } catch (_) {}
        }
      });
    }

    // 4. Dispose controllers outside the ±5 keep-alive window
    final Set<String> keepKeys = <String>{};
    for (int i = currentIndex - 5; i <= currentIndex + 5; i++) {
      if (i >= 0 && i < reels.length) {
        keepKeys.add(reels[i].id);
      }
    }

    final List<String> toRemove = _controllers.keys
        .where((String k) => !keepKeys.contains(k) && !_activeReelIds.contains(k))
        .toList();

    for (final String k in toRemove) {
      final VideoPlayerController? c = _controllers.remove(k);
      if (c != null) {
        try {
          c.pause();
          c.dispose();
        } catch (_) {}
      }
    }
  }

  /// Pause all active video controllers immediately and mute them.
  void pauseAll() {
    for (final VideoPlayerController c in _controllers.values) {
      try {
        c.pause();
        c.setVolume(0);
      } catch (_) {}
    }
  }

  /// Mute all controllers (set volume to 0) without pausing.
  void muteAll() {
    for (final VideoPlayerController c in _controllers.values) {
      try {
        c.setVolume(0);
      } catch (_) {}
    }
  }

  /// Restore volume on all controllers.
  void unmuteAll() {
    if (!_isFeedVisible) return;
    for (final VideoPlayerController c in _controllers.values) {
      try {
        if (c.value.isInitialized) c.setVolume(1.0);
      } catch (_) {}
    }
  }

  /// Mute every controller EXCEPT the one for [activeId].
  /// Ensures only the currently-visible reel can produce audio.
  void muteAllExcept(String activeId) {
    if (!_isFeedVisible) {
      pauseAll();
      muteAll();
      return;
    }
    for (final MapEntry<String, VideoPlayerController> entry in _controllers.entries) {
      try {
        if (entry.value.value.isInitialized) {
          entry.value.setVolume(entry.key == activeId ? 1.0 : 0.0);
        }
      } catch (_) {}
    }
  }

  /// Pause a specific controller by id.
  void pause(String id) {
    try {
      final VideoPlayerController? c = _controllers[id];
      if (c != null && c.value.isInitialized) c.pause();
    } catch (_) {}
  }

  /// Dispose all controllers when exiting the feed.
  void disposeAll() {
    for (final VideoPlayerController c in _controllers.values) {
      try {
        c.pause();
        c.dispose();
      } catch (_) {}
    }
    _controllers.clear();
    _initializing.clear();
  }

  /// Clear ALL caches — call on logout to free memory + disk.
  Future<void> clearAllCaches() async {
    disposeAll();
    _diskCachePathMap.clear();
    _cachingUrls.clear();
    _activeReelIds.clear();
    try {
      await ReelVideoCacheManager().emptyCache();
    } catch (_) {}
  }
}



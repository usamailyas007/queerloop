import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

import '../models/reel_item_model.dart';

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

  /// Downloads the video to disk (if not already cached) and returns the
  /// local [File]. Falls back to streaming if caching fails.
  Future<_VideoSource> _resolveSource(ReelItemModel reel) async {
    final String? filePath = reel.videoFilePath;
    if (filePath != null && filePath.isNotEmpty) {
      return _VideoSource.file(File(filePath));
    }

    final String? videoUrl = reel.videoUrl;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      final bool isHls =
          videoUrl.contains('.m3u8') || videoUrl.contains('m3u8');
      if (!isHls) {
        // 1. Fast in-memory path check
        if (_diskCachePathMap.containsKey(videoUrl)) {
          final File f = File(_diskCachePathMap[videoUrl]!);
          if (f.existsSync()) {
            return _VideoSource.file(f);
          }
        }

        // 2. Disk cache lookup
        try {
          final FileInfo? info =
              await ReelVideoCacheManager().getFileFromCache(videoUrl);
          if (info != null && info.file.existsSync()) {
            _diskCachePathMap[videoUrl] = info.file.path;
            debugPrint('✅ [ReelCache] Disk-cache hit: ${reel.id}');
            return _VideoSource.file(info.file);
          }
        } catch (_) {}

        // 3. Cache miss: Stream via network immediately without blocking!
        // Concurrently cache to disk in background for subsequent zero-lag hits
        _cacheVideoInBackground(videoUrl);
      }
      final Uri uri = Uri.parse(videoUrl);
      return _VideoSource.network(
        uri,
        formatHint: isHls ? VideoFormat.hls : null,
      );
    }

    if (reel.videoAsset.isNotEmpty) {
      return _VideoSource.asset(reel.videoAsset);
    }

    return _VideoSource.none();
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

      final _VideoSource source = await _resolveSource(reel);
      if (source.type == _SourceType.none) return null;

      switch (source.type) {
        case _SourceType.file:
          controller = VideoPlayerController.file(source.file!);
        case _SourceType.network:
          controller = VideoPlayerController.networkUrl(
            source.uri!,
            formatHint: source.formatHint,
          );
        case _SourceType.asset:
          controller = VideoPlayerController.asset(source.assetPath!);
        case _SourceType.none:
          return null;
      }

      _controllers[key] = controller;
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(1.0);

      return controller;
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
  /// Preloads: next 4 + prev 2. Keep-alive window: ±10 items.
  void preloadSurrounding(List<ReelItemModel> reels, int currentIndex) {
    if (reels.isEmpty) return;

    // 1. Background disk-cache upcoming 5 videos + previous 3 videos
    for (int i = currentIndex - 3; i <= currentIndex + 5; i++) {
      if (i >= 0 && i < reels.length) {
        final String? url = reels[i].videoUrl;
        if (url != null && url.isNotEmpty) {
          _cacheVideoInBackground(url);
        }
      }
    }

    // 2. Preload next 4 (highest priority for forward scrolling)
    for (int i = currentIndex + 1;
        i <= currentIndex + 4 && i < reels.length;
        i++) {
      getOrCreate(reels[i]);
    }
    // 3. Preload prev 2 (for scroll-back without re-buffering)
    for (int i = currentIndex - 1;
        i >= currentIndex - 2 && i >= 0;
        i--) {
      getOrCreate(reels[i]);
    }

    // 4. Dispose controllers outside the generous ±10 keep-alive window
    final Set<String> keepKeys = <String>{};
    for (int i = currentIndex - 10; i <= currentIndex + 10; i++) {
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

  /// Pause all active video controllers immediately.
  void pauseAll() {
    for (final VideoPlayerController c in _controllers.values) {
      try {
        if (c.value.isInitialized) c.pause();
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
}

// ── Internal helpers ──────────────────────────────────────────────────────────

enum _SourceType { file, network, asset, none }

class _VideoSource {
  const _VideoSource._({
    required this.type,
    this.file,
    this.uri,
    this.formatHint,
    this.assetPath,
  });

  factory _VideoSource.file(File f) =>
      _VideoSource._(type: _SourceType.file, file: f);

  factory _VideoSource.network(Uri uri, {VideoFormat? formatHint}) =>
      _VideoSource._(
          type: _SourceType.network, uri: uri, formatHint: formatHint);

  factory _VideoSource.asset(String path) =>
      _VideoSource._(type: _SourceType.asset, assetPath: path);

  factory _VideoSource.none() => const _VideoSource._(type: _SourceType.none);

  final _SourceType type;
  final File? file;
  final Uri? uri;
  final VideoFormat? formatHint;
  final String? assetPath;
}



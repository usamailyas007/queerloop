import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../models/reel_item_model.dart';

/// Centralized manager that pre-buffers and caches VideoPlayerControllers
/// for TikTok-style instant playback and adaptive HLS streaming.
class ReelVideoPreloader {
  ReelVideoPreloader._();
  static final ReelVideoPreloader instance = ReelVideoPreloader._();

  final Map<String, VideoPlayerController> _controllers = <String, VideoPlayerController>{};
  final Set<String> _initializing = <String>{};

  VideoPlayerController? getExisting(String id) => _controllers[id];

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
          debugPrint('⚠️ [ReelVideoPreloader] Error re-initializing controller $key: $e');
        } finally {
          _initializing.remove(key);
        }
      }
      return existing;
    }

    if (_initializing.contains(key)) {
      // Wait briefly if currently initializing
      int waitMs = 0;
      while (_initializing.contains(key) && waitMs < 3000) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        waitMs += 100;
      }
      return _controllers[key];
    }

    VideoPlayerController? controller;
    final String? filePath = reel.videoFilePath;
    final String? videoUrl = reel.videoUrl;

    try {
      _initializing.add(key);

      if (filePath != null && filePath.isNotEmpty) {
        controller = VideoPlayerController.file(File(filePath));
      } else if (videoUrl != null && videoUrl.isNotEmpty) {
        final Uri uri = Uri.parse(videoUrl);
        final bool isHls = uri.path.endsWith('.m3u8') || uri.query.contains('.m3u8');
        controller = VideoPlayerController.networkUrl(
          uri,
          formatHint: isHls ? VideoFormat.hls : null,
        );
      } else if (reel.videoAsset.isNotEmpty) {
        controller = VideoPlayerController.asset(reel.videoAsset);
      }

      if (controller == null) return null;

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

  /// Preload adjacent reels (next and previous) and dispose distant ones.
  void preloadSurrounding(List<ReelItemModel> reels, int currentIndex) {
    if (reels.isEmpty) return;

    // 1. Preload Next (Priority #1 for smooth scrolling)
    if (currentIndex + 1 < reels.length) {
      getOrCreate(reels[currentIndex + 1]);
    }
    // 2. Preload 2nd Next if possible
    if (currentIndex + 2 < reels.length) {
      getOrCreate(reels[currentIndex + 2]);
    }
    // 3. Preload Previous
    if (currentIndex - 1 >= 0) {
      getOrCreate(reels[currentIndex - 1]);
    }

    // 4. Dispose controllers outside of the active window [currentIndex - 2, currentIndex + 2]
    final Set<String> keepKeys = <String>{};
    for (int i = currentIndex - 2; i <= currentIndex + 2; i++) {
      if (i >= 0 && i < reels.length) {
        keepKeys.add(reels[i].id);
      }
    }

    final List<String> toRemove = _controllers.keys
        .where((String k) => !keepKeys.contains(k))
        .toList();

    for (final String key in toRemove) {
      final VideoPlayerController? c = _controllers.remove(key);
      if (c != null) {
        try {
          c.pause();
          c.dispose();
        } catch (_) {}
      }
    }
  }

  /// Dispose all controllers when exiting the feed
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

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Data model representing cached metadata of a shared post or reel in chat.
class SharedPostData {
  const SharedPostData({
    required this.postId,
    this.thumbnailUrl,
    this.caption,
    this.author,
    this.authorAvatarUrl,
    this.type = 'post',
    this.likes = 0,
    this.comments = 0,
  });

  final String postId;
  final String? thumbnailUrl;
  final String? caption;
  final String? author;
  final String? authorAvatarUrl;
  final String type; // 'post' or 'reel'
  final int likes;
  final int comments;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'postId': postId,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (caption != null) 'caption': caption,
        if (author != null) 'author': author,
        if (authorAvatarUrl != null) 'authorAvatarUrl': authorAvatarUrl,
        'type': type,
        'likes': likes,
        'comments': comments,
      };

  factory SharedPostData.fromJson(Map<String, dynamic> json) {
    return SharedPostData(
      postId: (json['postId'] ?? '').toString(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      caption: json['caption'] as String?,
      author: json['author'] as String?,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      type: (json['type'] ?? 'post').toString(),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Static in-memory + SharedPreferences disk cache for shared posts in chat.
/// Prevents redundant re-fetching and eliminates flickering/reloading on scroll.
class SharedPostCache {
  SharedPostCache._();

  static const String _prefKey = 'chat_shared_posts_cache_v1';
  static final Map<String, SharedPostData> _memoryCache =
      <String, SharedPostData>{};
  static bool _isInitialized = false;

  /// Initialize cache from SharedPreferences (lazy loaded on first call or startup)
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_prefKey);
      if (raw != null && raw.isNotEmpty) {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          for (final MapEntry<String, dynamic> entry in decoded.entries) {
            if (entry.value is Map<String, dynamic>) {
              _memoryCache[entry.key] = SharedPostData.fromJson(
                entry.value as Map<String, dynamic>,
              );
            }
          }
        }
      }
      _isInitialized = true;
      debugPrint(
        '✅ [SharedPostCache] Initialized with ${_memoryCache.length} cached post(s)',
      );
    } catch (e) {
      debugPrint('⚠️ [SharedPostCache] Failed to initialize: $e');
      _isInitialized = true;
    }
  }

  /// Synchronously retrieve cached shared post data from memory
  static SharedPostData? get(String? postId) {
    if (postId == null || postId.trim().isEmpty) return null;
    final String key = postId.trim();
    if (!_isInitialized) {
      init(); // trigger background load
    }
    return _memoryCache[key];
  }

  /// Store resolved post data in memory and persist asynchronously to SharedPreferences
  static Future<void> put(String postId, SharedPostData data) async {
    final String key = postId.trim();
    if (key.isEmpty) return;
    _memoryCache[key] = data;

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> serializable = <String, dynamic>{};
      // Keep most recent 500 cached posts
      final List<MapEntry<String, SharedPostData>> entries =
          _memoryCache.entries.toList();
      final int start = entries.length > 500 ? entries.length - 500 : 0;
      for (int i = start; i < entries.length; i++) {
        serializable[entries[i].key] = entries[i].value.toJson();
      }
      await prefs.setString(_prefKey, jsonEncode(serializable));
    } catch (e) {
      debugPrint('⚠️ [SharedPostCache] Error saving to disk: $e');
    }
  }

  /// Clear cache if needed (e.g. on logout)
  static void clearMemory() {
    _memoryCache.clear();
  }
}

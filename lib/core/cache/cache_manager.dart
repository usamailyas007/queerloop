import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline Cache Manager for API responses and persistent app state.
class CacheManager {
  CacheManager._();
  static final CacheManager instance = CacheManager._();

  static const String _keyPrefix = 'http_cache_';
  final Map<String, dynamic> _memoryCache = <String, dynamic>{};
  SharedPreferences? _prefs;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('⚠️ [CacheManager] Failed to initialize SharedPreferences: $e');
    }
  }

  /// Store dynamic data (JSON map, list, etc.) in cache with optional TTL.
  Future<void> put(String key, dynamic data, {Duration? ttl}) async {
    final String fullKey = '$_keyPrefix$key';
    _memoryCache[fullKey] = data;

    try {
      _prefs ??= await SharedPreferences.getInstance();
      final Map<String, dynamic> entry = <String, dynamic>{
        'data': data,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
        'ttl_ms': ttl?.inMilliseconds,
      };
      await _prefs?.setString(fullKey, jsonEncode(entry));
    } catch (e) {
      debugPrint('⚠️ [CacheManager] Could not persist key "$key": $e');
    }
  }

  /// Retrieve cached data. Returns null if missing or expired.
  dynamic get(String key) {
    final String fullKey = '$_keyPrefix$key';

    // 1. Fast in-memory lookup
    if (_memoryCache.containsKey(fullKey)) {
      return _memoryCache[fullKey];
    }

    // 2. Persistent storage lookup
    try {
      final String? raw = _prefs?.getString(fullKey);
      if (raw == null) {
        return null;
      }

      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final int? cachedAt = decoded['cached_at'] as int?;
        final int? ttlMs = decoded['ttl_ms'] as int?;

        // Check expiration if TTL was specified
        if (cachedAt != null && ttlMs != null) {
          final DateTime expiry =
              DateTime.fromMillisecondsSinceEpoch(cachedAt + ttlMs);
          if (DateTime.now().isAfter(expiry)) {
            remove(key);
            return null;
          }
        }

        final dynamic data = decoded['data'];
        _memoryCache[fullKey] = data;
        return data;
      }
    } catch (e) {
      debugPrint('⚠️ [CacheManager] Error reading key "$key": $e');
    }

    return null;
  }

  /// Remove a specific cache key.
  Future<void> remove(String key) async {
    final String fullKey = '$_keyPrefix$key';
    _memoryCache.remove(fullKey);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(fullKey);
  }

  /// Clear all HTTP response caches.
  Future<void> clearAll() async {
    _memoryCache.clear();
    _prefs ??= await SharedPreferences.getInstance();
    final Set<String> keys = _prefs?.getKeys() ?? <String>{};
    for (final String k in keys) {
      if (k.startsWith(_keyPrefix)) {
        await _prefs?.remove(k);
      }
    }
    debugPrint('🧹 [CacheManager] Cleared all API caches.');
  }
}

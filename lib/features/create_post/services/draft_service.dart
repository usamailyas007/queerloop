import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/post_draft_model.dart';

class DraftService {
  static const String _prefKey = 'saved_post_drafts';
  static final ValueNotifier<int> draftCountNotifier = ValueNotifier<int>(0);

  static Future<void> init() async {
    final List<PostDraft> drafts = await getDrafts();
    draftCountNotifier.value = drafts.length;
  }

  static Future<List<PostDraft>> getDrafts() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_prefKey);
      if (raw == null || raw.isEmpty) {
        return <PostDraft>[];
      }
      final dynamic decoded = jsonDecode(raw);
      if (decoded is List) {
        final List<PostDraft> list = decoded
            .map((dynamic item) =>
                PostDraft.fromJson(item as Map<String, dynamic>))
            .toList();
        list.sort((PostDraft a, PostDraft b) =>
            b.createdAt.compareTo(a.createdAt));
        draftCountNotifier.value = list.length;
        return list;
      }
    } catch (e) {
      debugPrint('⚠️ [DraftService] Failed to load drafts: $e');
    }
    return <PostDraft>[];
  }

  static Future<void> saveDraft(PostDraft draft) async {
    try {
      final List<PostDraft> drafts = await getDrafts();
      final int existingIndex =
          drafts.indexWhere((PostDraft d) => d.id == draft.id);
      if (existingIndex >= 0) {
        drafts[existingIndex] = draft;
      } else {
        drafts.insert(0, draft);
      }
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String encoded =
          jsonEncode(drafts.map((PostDraft d) => d.toJson()).toList());
      await prefs.setString(_prefKey, encoded);
      draftCountNotifier.value = drafts.length;
    } catch (e) {
      debugPrint('⚠️ [DraftService] Failed to save draft: $e');
    }
  }

  static Future<void> deleteDraft(String id) async {
    try {
      final List<PostDraft> drafts = await getDrafts();
      drafts.removeWhere((PostDraft d) => d.id == id);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String encoded =
          jsonEncode(drafts.map((PostDraft d) => d.toJson()).toList());
      await prefs.setString(_prefKey, encoded);
      draftCountNotifier.value = drafts.length;
    } catch (e) {
      debugPrint('⚠️ [DraftService] Failed to delete draft: $e');
    }
  }

  static Future<void> clearAll() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
      draftCountNotifier.value = 0;
    } catch (_) {}
  }
}

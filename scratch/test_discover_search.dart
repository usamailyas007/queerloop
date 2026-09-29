import 'dart:convert';
import 'dart:developer';
import 'dart:io';

void main() async {
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest req = await client.getUrl(
      Uri.parse('http://3.208.100.236:3001/discover/search?query=a&tab=all'),
    );
    final HttpClientResponse res = await req.close();
    final String body = await res.transform(utf8.decoder).join();
    log('STATUS: ${res.statusCode}');
    final dynamic data = jsonDecode(body);
    if (data is Map) {
      log('KEYS: ${data.keys.toList()}');
      if (data['posts'] is List) {
        final List posts = data['posts'];
        log('POSTS COUNT: ${posts.length}');
        if (posts.isNotEmpty) {
          log('SAMPLE POST: ${jsonEncode(posts.first)}');
        }
      }
      if (data['reels'] is List) {
        final List reels = data['reels'];
        log('REELS COUNT: ${reels.length}');
        if (reels.isNotEmpty) {
          log('SAMPLE REEL: ${jsonEncode(reels.first)}');
        }
      }
      if (data['data'] is Map) {
        final Map d = data['data'];
        log('DATA KEYS: ${d.keys.toList()}');
        if (d['posts'] is List) {
          final List posts = d['posts'];
          log('DATA POSTS COUNT: ${posts.length}');
          for (var p in posts.take(5)) {
            if (p is Map) {
              log('  DATA POST id=${p['id']} type=${p['type']} postType=${p['postType']} caption=${p['caption'] ?? p['content']}');
            }
          }
        }
        if (d['reels'] is List) {
          final List reels = d['reels'];
          log('DATA REELS COUNT: ${reels.length}');
          for (var r in reels.take(5)) {
            if (r is Map) {
              log('  DATA REEL id=${r['id']} type=${r['type']} postType=${r['postType']} caption=${r['caption'] ?? r['content']}');
            }
          }
        }
      }
    } else if (data is List) {
      log('LIST COUNT: ${data.length}');
    }
  } catch (e) {
    log('ERROR: $e');
  } finally {
    client.close();
  }
}

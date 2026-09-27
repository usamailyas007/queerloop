import 'dart:convert';
import 'dart:io';

void main() async {
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest req = await client.getUrl(
      Uri.parse('http://3.208.100.236:3001/discover/search?query=a&tab=all'),
    );
    final HttpClientResponse res = await req.close();
    final String body = await res.transform(utf8.decoder).join();
    print('STATUS: ${res.statusCode}');
    final dynamic data = jsonDecode(body);
    if (data is Map) {
      print('KEYS: ${data.keys.toList()}');
      if (data['posts'] is List) {
        final List posts = data['posts'];
        print('POSTS COUNT: ${posts.length}');
        if (posts.isNotEmpty) {
          print('SAMPLE POST: ${jsonEncode(posts.first)}');
        }
      }
      if (data['reels'] is List) {
        final List reels = data['reels'];
        print('REELS COUNT: ${reels.length}');
        if (reels.isNotEmpty) {
          print('SAMPLE REEL: ${jsonEncode(reels.first)}');
        }
      }
      if (data['data'] is Map) {
        final Map d = data['data'];
        print('DATA KEYS: ${d.keys.toList()}');
        if (d['posts'] is List) {
          final List posts = d['posts'];
          print('DATA POSTS COUNT: ${posts.length}');
          for (var p in posts.take(5)) {
            if (p is Map) {
              print('  DATA POST id=${p['id']} type=${p['type']} postType=${p['postType']} caption=${p['caption'] ?? p['content']}');
            }
          }
        }
        if (d['reels'] is List) {
          final List reels = d['reels'];
          print('DATA REELS COUNT: ${reels.length}');
          for (var r in reels.take(5)) {
            if (r is Map) {
              print('  DATA REEL id=${r['id']} type=${r['type']} postType=${r['postType']} caption=${r['caption'] ?? r['content']}');
            }
          }
        }
      }
    } else if (data is List) {
      print('LIST COUNT: ${data.length}');
    }
  } catch (e) {
    print('ERROR: $e');
  } finally {
    client.close();
  }
}

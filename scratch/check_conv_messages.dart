import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final convId = 'f8a0b66f-e15c-4265-a1d1-54d6a318da1d';

  print('Fetching messages for conversation $convId...');
  final req = await client.getUrl(Uri.parse('http://3.208.100.236:3001/conversations/$convId/messages'));
  final res = await req.close();
  final body = await utf8.decoder.bind(res).join();
  print('Status: ${res.statusCode}');
  try {
    final parsed = jsonDecode(body);
    if (parsed is List) {
      print('Total messages: ${parsed.length}');
      for (final m in parsed) {
        print('----------------------------------------');
        print('ID: ${m['id']}');
        print('Sender: ${m['senderId']}');
        print('Body: ${m['body']}');
        print('replyToMessageId: ${m['replyToMessageId']}');
        print('replyTo: ${m['replyTo']}');
        print('CreatedAt: ${m['createdAt']}');
      }
    } else {
      print(const JsonEncoder.withIndent('  ').convert(parsed));
    }
  } catch (e) {
    print(body);
  }
}

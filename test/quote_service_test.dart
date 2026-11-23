import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lifemeter/services/quote_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final day = DateTime(2026, 11, 23, 9);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fetches the quote of the day once and caches it', () async {
    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      expect(req.url.toString(), 'https://zenquotes.io/api/today');
      return http.Response(
        jsonEncode([
          {'q': 'Have a vision. Be demanding.', 'a': 'Colin Powell'},
        ]),
        200,
      );
    });
    final service = QuoteService(client: client);

    final first = await service.today(now: day);
    expect(first.text, 'Have a vision. Be demanding.');
    expect(first.author, 'Colin Powell');
    expect(first.fromZenQuotes, isTrue);

    final again = await service.today(now: day.add(const Duration(hours: 5)));
    expect(again.text, first.text);
    expect(calls, 1, reason: 'same day comes from the cache');

    await service.today(now: day.add(const Duration(days: 1)));
    expect(calls, 2, reason: 'a new day fetches again');
  });

  test('ignores the rate-limit notice and falls back', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode([
          {'q': 'Too many requests. Obtain an auth key.', 'a': 'zenquotes.io'},
        ]),
        200,
      ),
    );
    final q = await QuoteService(client: client).today(now: day);
    expect(q.fromZenQuotes, isFalse);
    expect(QuoteService.fallback.map((f) => f.text), contains(q.text));
  });

  test('falls back offline', () async {
    final client = MockClient((_) async => throw http.ClientException('off'));
    final q = await QuoteService(client: client).today(now: day);
    expect(q.fromZenQuotes, isFalse);
    expect(q.text, QuoteService.fallbackFor(day).text);
  });
}

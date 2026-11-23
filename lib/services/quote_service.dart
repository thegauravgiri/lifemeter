import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Quote {
  const Quote(this.text, this.author, {this.fromZenQuotes = false});

  final String text;
  final String author;

  /// ZenQuotes' free tier asks for a visible credit link.
  final bool fromZenQuotes;
}

/// Quote of the day from ZenQuotes (https://zenquotes.io), free and keyless.
///
/// Fetched at most once per day and cached, which keeps well inside the free
/// limit of 5 requests per 30 seconds. Only the request itself leaves the
/// phone: nothing about the user is sent. Offline, or if the service is
/// unavailable, a bundled line about time is shown instead.
class QuoteService {
  QuoteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final _today = Uri.parse('https://zenquotes.io/api/today');
  static const _cacheKey = 'quote_of_day_v1';

  Future<Quote> today({DateTime? now}) async {
    final day = _dayKey(now ?? DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final cached = _decode(prefs.getString(_cacheKey), day);
    if (cached != null) return cached;

    try {
      final res = await _client.get(_today).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body);
        if (list is List && list.isNotEmpty && list.first is Map) {
          final q = (list.first['q'] as String?)?.trim() ?? '';
          final a = (list.first['a'] as String?)?.trim() ?? '';
          // When rate-limited, ZenQuotes returns its own notice as a "quote"
          // attributed to zenquotes.io; don't show that.
          if (q.isNotEmpty && a.isNotEmpty && !a.contains('zenquotes')) {
            await prefs.setString(
              _cacheKey,
              jsonEncode({'day': day, 'q': q, 'a': a}),
            );
            return Quote(q, a, fromZenQuotes: true);
          }
        }
      }
    } catch (e) {
      debugPrint('Quote of the day unavailable: $e');
    }
    return fallbackFor(now ?? DateTime.now());
  }

  static Quote? _decode(String? raw, String day) {
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if (m['day'] != day) return null;
      return Quote(m['q'] as String, m['a'] as String, fromZenQuotes: true);
    } catch (_) {
      return null;
    }
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Public-domain lines about time, one per day, for offline use.
  static Quote fallbackFor(DateTime d) {
    final dayOfYear = d.difference(DateTime(d.year)).inDays;
    return fallback[(dayOfYear + d.year) % fallback.length];
  }

  static const fallback = <Quote>[
    Quote(
      'It is not that we have a short time to live, but that we waste a lot of it.',
      'Seneca',
    ),
    Quote('While we are postponing, life speeds by.', 'Seneca'),
    Quote(
      'Begin at once to live, and count each separate day as a separate life.',
      'Seneca',
    ),
    Quote('Life is long, if you know how to use it.', 'Seneca'),
    Quote(
      'Do not act as if you had ten thousand years to live.',
      'Marcus Aurelius',
    ),
    Quote(
      'Seize the day, putting as little trust as possible in tomorrow.',
      'Horace',
    ),
    Quote(
      'As if you could kill time without injuring eternity.',
      'Henry David Thoreau',
    ),
    Quote('Lost time is never found again.', 'Benjamin Franklin'),
  ];
}

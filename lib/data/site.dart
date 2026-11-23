import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// LifeMeter's pages on the web. Everything public about the app lives on
/// lifemeter.gauravgiri.com.np; the sources for these pages are in `site/`.
abstract final class Site {
  static const host = 'lifemeter.gauravgiri.com.np';
  static final home = Uri.https(host, '/');
  static final privacy = Uri.https(host, '/privacy');
  static final terms = Uri.https(host, '/terms');
  static final support = Uri.https(host, '/support');
  static final method = Uri.https(host, '/how-it-works');
}

/// Opens a LifeMeter page in the browser; shows the address if that fails.
Future<void> openSite(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ok = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  ).catchError((_) => false);
  if (!ok) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text('Couldn’t open a browser. Visit ${uri.host}${uri.path}'),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens external URLs (privacy policy, terms, store listing).
///
/// Failures are swallowed on purpose: an unopenable link is a dead end for the
/// user either way, and none of these are part of a task they can't finish.
abstract final class LinkService {
  static Future<bool> open(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// The store listing for the current platform.
  static String storeUrl({
    required String androidUrl,
    required String iosUrl,
  }) => defaultTargetPlatform == TargetPlatform.iOS ? iosUrl : androidUrl;
}

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:health_forge_example/oauth_redirect.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bridges url_launcher and app_links to implement the OAuth redirect flow.
///
/// Opens the authorization URL in the system browser and waits for the
/// deep-link redirect to return the authorization code.
class OAuthHelper {
  /// [allowedRedirectUris] — when non-empty, only deep links whose
  /// scheme, host, port, and path match one of these registered URIs will
  /// complete the pending OAuth wait (others are ignored).
  OAuthHelper({Iterable<String>? allowedRedirectUris})
      : _allowedRedirects = allowedRedirectUris == null
            ? const []
            : allowedRedirectUris.map(Uri.parse).toList(growable: false) {
    _appLinks = AppLinks();
    _subscription = _appLinks.uriLinkStream.listen(_onDeepLink);
  }

  late final AppLinks _appLinks;
  late final StreamSubscription<Uri> _subscription;
  Completer<String?>? _pendingAuth;
  final List<Uri> _allowedRedirects;

  void _onDeepLink(Uri uri) {
    if (_pendingAuth == null || _pendingAuth!.isCompleted) return;
    if (_allowedRedirects.isNotEmpty) {
      final ok = _allowedRedirects.any((e) => oauthRedirectMatches(uri, e));
      if (!ok) return;
    }
    _pendingAuth!.complete(uri.toString());
  }

  /// Opens [authUrl] in the system browser and waits for the redirect.
  ///
  /// Returns the full redirect URL string, or `null` on timeout/cancel.
  Future<String?> launch(Uri authUrl) async {
    _pendingAuth = Completer<String?>();

    final launched = await launchUrl(
      authUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) return null;

    return _pendingAuth!.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => null,
    );
  }

  void dispose() {
    unawaited(_subscription.cancel());
  }
}

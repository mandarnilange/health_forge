/// Normalizes path segments for OAuth redirect URI comparison.
String normalizeOAuthRedirectPath(String path) {
  if (path.isEmpty) return '';
  return path.startsWith('/') ? path : '/$path';
}

/// Whether [received] matches [expected]
/// (scheme, host, port, path; case-folded).
bool oauthRedirectMatches(Uri received, Uri expected) {
  return received.scheme.toLowerCase() == expected.scheme.toLowerCase() &&
      received.host.toLowerCase() == expected.host.toLowerCase() &&
      received.port == expected.port &&
      normalizeOAuthRedirectPath(received.path) ==
          normalizeOAuthRedirectPath(expected.path);
}

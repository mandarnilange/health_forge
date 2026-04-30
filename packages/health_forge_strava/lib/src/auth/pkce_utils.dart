import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// PKCE (Proof Key for Code Exchange) utilities for OAuth 2.0.
///
/// Implements RFC 7636 code verifier generation and S256 code challenge
/// derivation.
class PkceUtils {
  const PkceUtils._();

  static const _charset =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  /// Generates a cryptographically random code verifier.
  ///
  /// The [length] must be between 43 and 128 (inclusive) per RFC 7636.
  /// Defaults to 128.
  static String generateCodeVerifier({int length = 128}) {
    final random = Random.secure();
    return List.generate(
      length,
      (_) => _charset[random.nextInt(_charset.length)],
    ).join();
  }

  /// Derives a code challenge from [codeVerifier] using S256.
  ///
  /// Returns the base64url-encoded SHA-256 digest with padding stripped.
  static String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}

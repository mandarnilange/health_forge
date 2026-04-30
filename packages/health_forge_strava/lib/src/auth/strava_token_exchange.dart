import 'package:health_forge_strava/src/auth/strava_token.dart';

/// Performs Strava OAuth token exchange and refresh **without** using a
/// `client_secret` inside the app.
///
/// Implement this by calling your own backend (or a BFF) that holds the
/// Strava client secret and proxies requests to Strava's token endpoint.
/// Pass an instance to `StravaAuthManager`'s `tokenExchange` argument and
/// omit `clientSecret`.
abstract class StravaTokenExchange {
  /// Exchanges an authorization [code] for tokens (authorization_code grant).
  Future<StravaToken> exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  });

  /// Refreshes tokens using Strava's refresh_token grant.
  Future<StravaToken> refreshAccessToken({
    required String refreshToken,
  });
}

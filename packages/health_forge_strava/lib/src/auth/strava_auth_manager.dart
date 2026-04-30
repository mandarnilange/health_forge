import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:health_forge_strava/src/api/strava_api_endpoints.dart';
import 'package:health_forge_strava/src/auth/pkce_utils.dart';
import 'package:health_forge_strava/src/auth/strava_token.dart';
import 'package:health_forge_strava/src/auth/strava_token_exchange.dart';

/// Manages OAuth 2.0 PKCE authentication with the Strava API.
///
/// **Security:** Strava's token endpoint requires a `client_secret`. You can
/// either:
///
/// 1. **Recommended for production:** Provide `tokenExchange` only and perform
///    exchange/refresh on your backend (secret never ships in the app).
/// 2. **Development / constrained setups:** Provide `clientSecret` for
///    direct calls from the app (secret is recoverable from the binary).
///
/// Provide exactly one of `clientSecret` or `tokenExchange`.
class StravaAuthManager {
  /// Creates an auth manager with the given OAuth configuration.
  ///
  /// The `urlLauncher` callback presents the authorization URL to the user
  /// and returns the redirect result. An optional `dio` can be injected when
  /// using `clientSecret` (defaults to a new Dio instance).
  StravaAuthManager({
    required this.clientId,
    required this.redirectUri,
    required Future<String?> Function(Uri authUrl) urlLauncher,
    String? clientSecret,
    StravaTokenExchange? tokenExchange,
    Dio? dio,
    StravaToken? initialToken,
    void Function(StravaToken?)? onTokenChanged,
  })  : _clientSecret = clientSecret,
        _tokenExchange = tokenExchange,
        _urlLauncher = urlLauncher,
        _dio = tokenExchange == null ? (dio ?? Dio()) : dio,
        _currentToken = initialToken,
        _onTokenChanged = onTokenChanged {
    if (!((tokenExchange != null) ^
        (clientSecret != null && clientSecret.isNotEmpty))) {
      throw ArgumentError(
        'Provide exactly one of clientSecret or tokenExchange.',
      );
    }
  }

  /// The OAuth 2.0 client identifier.
  final String clientId;

  /// The OAuth 2.0 client secret, when using direct token calls from the app.
  ///
  /// Null when a `tokenExchange` is used.
  final String? _clientSecret;

  /// Optional backend/BFF token exchange (no in-app secret).
  final StravaTokenExchange? _tokenExchange;

  /// The OAuth 2.0 redirect URI registered with Strava.
  final String redirectUri;
  final Future<String?> Function(Uri authUrl) _urlLauncher;
  final Dio? _dio;
  final void Function(StravaToken?)? _onTokenChanged;

  StravaToken? _currentToken;

  /// The current OAuth token, if authorized.
  StravaToken? get currentToken => _currentToken;

  /// Initiates the OAuth 2.0 PKCE authorization flow.
  ///
  /// Returns the [StravaToken] on success, or `null` if the user cancels
  /// or the redirect URL cannot be parsed.
  Future<StravaToken?> authorize() async {
    final codeVerifier = PkceUtils.generateCodeVerifier();
    final codeChallenge = PkceUtils.generateCodeChallenge(codeVerifier);
    final state = PkceUtils.generateCodeVerifier(length: 43);

    final authUrl = Uri.parse(StravaApiEndpoints.authorizeUrl).replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'activity:read_all',
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
      },
    );

    final redirectResult = await _urlLauncher(authUrl);
    if (redirectResult == null) return null;

    final redirectedUri = Uri.parse(redirectResult);

    // Validate state to prevent CSRF / authorization response injection.
    final returnedState = redirectedUri.queryParameters['state'];
    if (returnedState != state) return null;

    final code = redirectedUri.queryParameters['code'];
    if (code == null) return null;

    return _exchangeCodeForToken(code, codeVerifier);
  }

  /// Refreshes an expired token using its refresh token.
  ///
  /// Returns a new [StravaToken] on success, or `null` on failure.
  Future<StravaToken?> refreshToken(StravaToken token) async {
    try {
      final StravaToken newToken;
      final exchange = _tokenExchange;
      if (exchange != null) {
        newToken = await exchange.refreshAccessToken(
          refreshToken: token.refreshToken,
        );
      } else {
        final response = await _dio!.postUri<dynamic>(
          Uri.parse(StravaApiEndpoints.tokenUrl),
          data: {
            'grant_type': 'refresh_token',
            'client_id': clientId,
            'client_secret': _clientSecret,
            'refresh_token': token.refreshToken,
          },
          options: Options(contentType: Headers.formUrlEncodedContentType),
        );
        newToken = _parseTokenResponse(response);
      }
      _currentToken = newToken;
      _onTokenChanged?.call(newToken);
      return newToken;
    } on DioException {
      return null;
    }
  }

  /// Clears the current token (for deauthorization).
  void clearToken() {
    _currentToken = null;
    _onTokenChanged?.call(null);
  }

  Future<StravaToken?> _exchangeCodeForToken(
    String code,
    String codeVerifier,
  ) async {
    try {
      final StravaToken token;
      final exchange = _tokenExchange;
      if (exchange != null) {
        token = await exchange.exchangeAuthorizationCode(
          code: code,
          codeVerifier: codeVerifier,
          redirectUri: redirectUri,
        );
      } else {
        final response = await _dio!.postUri<dynamic>(
          Uri.parse(StravaApiEndpoints.tokenUrl),
          data: {
            'grant_type': 'authorization_code',
            'client_id': clientId,
            'client_secret': _clientSecret,
            'code': code,
            'redirect_uri': redirectUri,
            'code_verifier': codeVerifier,
          },
          options: Options(contentType: Headers.formUrlEncodedContentType),
        );
        token = _parseTokenResponse(response);
      }
      _currentToken = token;
      _onTokenChanged?.call(token);
      return token;
    } on DioException {
      return null;
    }
  }

  StravaToken _parseTokenResponse(Response<dynamic> response) {
    final body = response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : response.data as Map<String, dynamic>;

    return StravaToken(
      accessToken: body['access_token'] as String,
      refreshToken: body['refresh_token'] as String,
      expiresAt: DateTime.now().add(
        Duration(seconds: body['expires_in'] as int),
      ),
    );
  }
}

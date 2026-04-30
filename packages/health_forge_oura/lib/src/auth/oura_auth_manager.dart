import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:health_forge_oura/src/api/oura_api_endpoints.dart';
import 'package:health_forge_oura/src/auth/oura_token.dart';
import 'package:health_forge_oura/src/auth/pkce_utils.dart';

/// Manages OAuth 2.0 PKCE authentication with the Oura Ring API.
class OuraAuthManager {
  /// Creates an auth manager with the given OAuth [clientId] and [redirectUri].
  ///
  /// The [urlLauncher] callback presents the authorization URL to the user
  /// and returns the redirect result. An optional [dio] can be injected.
  OuraAuthManager({
    required this.clientId,
    required this.redirectUri,
    required Future<String?> Function(Uri authUrl) urlLauncher,
    Dio? dio,
    OuraToken? initialToken,
    void Function(OuraToken?)? onTokenChanged,
  })  : _urlLauncher = urlLauncher,
        _dio = dio ?? Dio(),
        _currentToken = initialToken,
        _onTokenChanged = onTokenChanged;

  /// The OAuth 2.0 client identifier.
  final String clientId;

  /// The OAuth 2.0 redirect URI registered with Oura.
  final String redirectUri;
  final Future<String?> Function(Uri authUrl) _urlLauncher;
  final Dio _dio;
  final void Function(OuraToken?)? _onTokenChanged;

  OuraToken? _currentToken;

  /// The current OAuth token, if authorized.
  OuraToken? get currentToken => _currentToken;

  /// Initiates the OAuth 2.0 PKCE authorization flow.
  ///
  /// Returns the [OuraToken] on success, or `null` if the user cancels
  /// or the redirect URL cannot be parsed.
  Future<OuraToken?> authorize() async {
    final codeVerifier = PkceUtils.generateCodeVerifier();
    final codeChallenge = PkceUtils.generateCodeChallenge(codeVerifier);
    final state = PkceUtils.generateCodeVerifier(length: 43);

    final authUrl = Uri.parse(OuraApiEndpoints.authorizeUrl).replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
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
  /// Returns a new [OuraToken] on success, or `null` on failure.
  Future<OuraToken?> refreshToken(OuraToken token) async {
    try {
      final response = await _dio.postUri<dynamic>(
        Uri.parse(OuraApiEndpoints.tokenUrl),
        data: {
          'grant_type': 'refresh_token',
          'client_id': clientId,
          'refresh_token': token.refreshToken,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final newToken = _parseTokenResponse(response);
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

  Future<OuraToken?> _exchangeCodeForToken(
    String code,
    String codeVerifier,
  ) async {
    try {
      final response = await _dio.postUri<dynamic>(
        Uri.parse(OuraApiEndpoints.tokenUrl),
        data: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'code': code,
          'redirect_uri': redirectUri,
          'code_verifier': codeVerifier,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final token = _parseTokenResponse(response);
      _currentToken = token;
      _onTokenChanged?.call(token);
      return token;
    } on DioException {
      return null;
    }
  }

  OuraToken _parseTokenResponse(Response<dynamic> response) {
    final body = response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : response.data as Map<String, dynamic>;

    return OuraToken(
      accessToken: body['access_token'] as String,
      refreshToken: body['refresh_token'] as String,
      expiresAt: DateTime.now().add(
        Duration(seconds: body['expires_in'] as int),
      ),
    );
  }
}

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_oura/src/api/oura_api_endpoints.dart';
import 'package:health_forge_oura/src/auth/oura_auth_manager.dart';
import 'package:health_forge_oura/src/auth/oura_token.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late OuraAuthManager authManager;
  late MockDio mockDio;
  late Uri? capturedAuthUrl;

  setUp(() {
    mockDio = MockDio();
    capturedAuthUrl = null;

    authManager = OuraAuthManager(
      clientId: 'test-client-id',
      redirectUri: 'com.test.app://callback',
      urlLauncher: (url) async {
        capturedAuthUrl = url;
        // Simulate the redirect with an auth code and echo back state
        final state = url.queryParameters['state'] ?? '';
        final redirect = url.queryParameters['redirect_uri'];
        return '$redirect?code=test-auth-code&state=$state';
      },
      dio: mockDio,
    );
  });

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('OuraAuthManager', () {
    group('authorize', () {
      test('builds authorization URL with PKCE parameters', () async {
        when(
          () => mockDio.postUri<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: jsonEncode({
              'access_token': 'test-access-token',
              'refresh_token': 'test-refresh-token',
              'expires_in': 3600,
            }),
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        await authManager.authorize();

        expect(capturedAuthUrl, isNotNull);
        expect(
          capturedAuthUrl!.toString(),
          startsWith(OuraApiEndpoints.authorizeUrl),
        );
        expect(capturedAuthUrl!.queryParameters['client_id'], 'test-client-id');
        expect(
          capturedAuthUrl!.queryParameters['redirect_uri'],
          'com.test.app://callback',
        );
        expect(capturedAuthUrl!.queryParameters['response_type'], 'code');
        expect(
          capturedAuthUrl!.queryParameters['code_challenge_method'],
          'S256',
        );
        expect(
          capturedAuthUrl!.queryParameters['code_challenge'],
          isNotEmpty,
        );
      });

      test('exchanges code for token on success', () async {
        when(
          () => mockDio.postUri<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: jsonEncode({
              'access_token': 'test-access-token',
              'refresh_token': 'test-refresh-token',
              'expires_in': 3600,
            }),
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final token = await authManager.authorize();

        expect(token, isNotNull);
        expect(token!.accessToken, 'test-access-token');
        expect(token.refreshToken, 'test-refresh-token');
        expect(token.isExpired, isFalse);
      });

      test('returns null when urlLauncher returns null', () async {
        authManager = OuraAuthManager(
          clientId: 'test-client-id',
          redirectUri: 'com.test.app://callback',
          urlLauncher: (_) async => null,
          dio: mockDio,
        );

        final token = await authManager.authorize();
        expect(token, isNull);
      });
    });

    group('refreshToken', () {
      test('exchanges refresh token for new token set', () async {
        when(
          () => mockDio.postUri<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: jsonEncode({
              'access_token': 'new-access-token',
              'refresh_token': 'new-refresh-token',
              'expires_in': 3600,
            }),
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final existingToken = OuraToken(
          accessToken: 'old-access-token',
          refreshToken: 'old-refresh-token',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        final newToken = await authManager.refreshToken(existingToken);

        expect(newToken, isNotNull);
        expect(newToken!.accessToken, 'new-access-token');
        expect(newToken.refreshToken, 'new-refresh-token');
      });

      test('returns null on DioException', () async {
        when(
          () => mockDio.postUri<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.badResponse,
          ),
        );

        final existingToken = OuraToken(
          accessToken: 'old',
          refreshToken: 'old-refresh',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        final result = await authManager.refreshToken(existingToken);
        expect(result, isNull);
      });
    });

    group('currentToken', () {
      test('is null initially', () {
        expect(authManager.currentToken, isNull);
      });

      test('is set after authorize', () async {
        when(
          () => mockDio.postUri<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: jsonEncode({
              'access_token': 'at',
              'refresh_token': 'rt',
              'expires_in': 3600,
            }),
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        await authManager.authorize();
        expect(authManager.currentToken, isNotNull);
        expect(authManager.currentToken!.accessToken, 'at');
      });
    });

    group('initialToken', () {
      test('sets currentToken from constructor', () {
        final token = OuraToken(
          accessToken: 'restored-at',
          refreshToken: 'restored-rt',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        final manager = OuraAuthManager(
          clientId: 'test-client-id',
          redirectUri: 'com.test.app://callback',
          urlLauncher: (_) async => null,
          dio: mockDio,
          initialToken: token,
        );

        expect(manager.currentToken, isNotNull);
        expect(manager.currentToken!.accessToken, 'restored-at');
      });
    });

    group('onTokenChanged', () {
      test('is called on authorize', () async {
        OuraToken? callbackToken;
        var callCount = 0;

        final manager = OuraAuthManager(
          clientId: 'test-client-id',
          redirectUri: 'com.test.app://callback',
          urlLauncher: (url) async {
            final state = url.queryParameters['state'] ?? '';
            final redirect = url.queryParameters['redirect_uri'];
            return '$redirect?code=test-auth-code&state=$state';
          },
          dio: mockDio,
          onTokenChanged: (token) {
            callbackToken = token;
            callCount++;
          },
        );

        when(
          () => mockDio.postUri<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: jsonEncode({
              'access_token': 'new-at',
              'refresh_token': 'new-rt',
              'expires_in': 3600,
            }),
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        await manager.authorize();

        expect(callCount, 1);
        expect(callbackToken, isNotNull);
        expect(callbackToken!.accessToken, 'new-at');
      });

      test('is called on refreshToken', () async {
        OuraToken? callbackToken;
        var callCount = 0;

        final manager = OuraAuthManager(
          clientId: 'test-client-id',
          redirectUri: 'com.test.app://callback',
          urlLauncher: (_) async => null,
          dio: mockDio,
          onTokenChanged: (token) {
            callbackToken = token;
            callCount++;
          },
        );

        when(
          () => mockDio.postUri<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: jsonEncode({
              'access_token': 'refreshed-at',
              'refresh_token': 'refreshed-rt',
              'expires_in': 3600,
            }),
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final existingToken = OuraToken(
          accessToken: 'old',
          refreshToken: 'old-rt',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        await manager.refreshToken(existingToken);

        expect(callCount, 1);
        expect(callbackToken, isNotNull);
        expect(callbackToken!.accessToken, 'refreshed-at');
      });
    });

    group('state parameter', () {
      test('authorization URL includes state parameter', () async {
        when(
          () => mockDio.postUri<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: jsonEncode({
              'access_token': 'at',
              'refresh_token': 'rt',
              'expires_in': 3600,
            }),
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        await authManager.authorize();

        expect(capturedAuthUrl, isNotNull);
        expect(
          capturedAuthUrl!.queryParameters['state'],
          isNotEmpty,
        );
      });

      test('returns null when state mismatch in redirect', () async {
        authManager = OuraAuthManager(
          clientId: 'test-client-id',
          redirectUri: 'com.test.app://callback',
          urlLauncher: (url) async {
            capturedAuthUrl = url;
            return 'com.test.app://callback?code=test-code&state=wrong-state';
          },
          dio: mockDio,
        );

        final token = await authManager.authorize();
        expect(token, isNull);
      });

      test('returns null when state is missing from redirect', () async {
        authManager = OuraAuthManager(
          clientId: 'test-client-id',
          redirectUri: 'com.test.app://callback',
          urlLauncher: (url) async {
            capturedAuthUrl = url;
            return 'com.test.app://callback?code=test-code';
          },
          dio: mockDio,
        );

        final token = await authManager.authorize();
        expect(token, isNull);
      });
    });

    group('clearToken', () {
      test('sets currentToken to null', () async {
        when(
          () => mockDio.postUri<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: jsonEncode({
              'access_token': 'at',
              'refresh_token': 'rt',
              'expires_in': 3600,
            }),
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        await authManager.authorize();
        expect(authManager.currentToken, isNotNull);

        authManager.clearToken();
        expect(authManager.currentToken, isNull);
      });

      test('calls onTokenChanged with null', () {
        OuraToken? callbackToken = OuraToken(
          accessToken: 'sentinel',
          refreshToken: 'sentinel',
          expiresAt: DateTime.now(),
        );
        var callCount = 0;

        final manager = OuraAuthManager(
          clientId: 'test-client-id',
          redirectUri: 'com.test.app://callback',
          urlLauncher: (_) async => null,
          dio: mockDio,
          initialToken: OuraToken(
            accessToken: 'at',
            refreshToken: 'rt',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
          onTokenChanged: (token) {
            callbackToken = token;
            callCount++;
          },
        )..clearToken();

        expect(callCount, 1);
        expect(callbackToken, isNull);
        expect(manager.currentToken, isNull);
      });
    });
  });
}

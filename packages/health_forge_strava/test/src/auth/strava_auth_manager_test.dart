import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_strava/src/api/strava_api_endpoints.dart';
import 'package:health_forge_strava/src/auth/strava_auth_manager.dart';
import 'package:health_forge_strava/src/auth/strava_token.dart';
import 'package:health_forge_strava/src/auth/strava_token_exchange.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockStravaTokenExchange extends Mock implements StravaTokenExchange {}

void main() {
  late StravaAuthManager authManager;
  late MockDio mockDio;
  late Uri? capturedAuthUrl;

  setUp(() {
    mockDio = MockDio();
    capturedAuthUrl = null;

    authManager = StravaAuthManager(
      clientId: 'test-client-id',
      clientSecret: 'test-client-secret',
      redirectUri: 'com.test.app://callback',
      urlLauncher: (url) async {
        capturedAuthUrl = url;
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

  group('StravaAuthManager', () {
    group('authorize', () {
      test('builds authorization URL with PKCE parameters and scope', () async {
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
          startsWith(StravaApiEndpoints.authorizeUrl),
        );
        expect(
          capturedAuthUrl!.queryParameters['client_id'],
          'test-client-id',
        );
        expect(
          capturedAuthUrl!.queryParameters['redirect_uri'],
          'com.test.app://callback',
        );
        expect(capturedAuthUrl!.queryParameters['response_type'], 'code');
        expect(
          capturedAuthUrl!.queryParameters['scope'],
          'activity:read_all',
        );
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

      test('sends client_secret in token exchange', () async {
        Map<String, dynamic>? capturedData;

        when(
          () => mockDio.postUri<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((invocation) async {
          capturedData =
              invocation.namedArguments[#data] as Map<String, dynamic>;
          return Response(
            data: jsonEncode({
              'access_token': 'at',
              'refresh_token': 'rt',
              'expires_in': 3600,
            }),
            statusCode: 200,
            requestOptions: RequestOptions(),
          );
        });

        await authManager.authorize();

        expect(capturedData, isNotNull);
        expect(capturedData!['client_secret'], 'test-client-secret');
      });

      test('returns null when urlLauncher returns null', () async {
        authManager = StravaAuthManager(
          clientId: 'test-client-id',
          clientSecret: 'test-client-secret',
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

        final existingToken = StravaToken(
          accessToken: 'old-access-token',
          refreshToken: 'old-refresh-token',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        final newToken = await authManager.refreshToken(existingToken);

        expect(newToken, isNotNull);
        expect(newToken!.accessToken, 'new-access-token');
        expect(newToken.refreshToken, 'new-refresh-token');
      });

      test('sends client_secret in refresh request', () async {
        Map<String, dynamic>? capturedData;

        when(
          () => mockDio.postUri<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((invocation) async {
          capturedData =
              invocation.namedArguments[#data] as Map<String, dynamic>;
          return Response(
            data: jsonEncode({
              'access_token': 'at',
              'refresh_token': 'rt',
              'expires_in': 3600,
            }),
            statusCode: 200,
            requestOptions: RequestOptions(),
          );
        });

        final existingToken = StravaToken(
          accessToken: 'old',
          refreshToken: 'old-refresh',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        await authManager.refreshToken(existingToken);

        expect(capturedData, isNotNull);
        expect(capturedData!['client_secret'], 'test-client-secret');
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

        final existingToken = StravaToken(
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
        final token = StravaToken(
          accessToken: 'restored-at',
          refreshToken: 'restored-rt',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        final manager = StravaAuthManager(
          clientId: 'test-client-id',
          clientSecret: 'test-client-secret',
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
        StravaToken? callbackToken;
        var callCount = 0;

        final manager = StravaAuthManager(
          clientId: 'test-client-id',
          clientSecret: 'test-client-secret',
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
        StravaToken? callbackToken;
        var callCount = 0;

        final manager = StravaAuthManager(
          clientId: 'test-client-id',
          clientSecret: 'test-client-secret',
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

        final existingToken = StravaToken(
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
        authManager = StravaAuthManager(
          clientId: 'test-client-id',
          clientSecret: 'test-client-secret',
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
        authManager = StravaAuthManager(
          clientId: 'test-client-id',
          clientSecret: 'test-client-secret',
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

    group('configuration', () {
      test('throws when both clientSecret and tokenExchange are provided', () {
        final exchange = MockStravaTokenExchange();
        expect(
          () => StravaAuthManager(
            clientId: 'id',
            clientSecret: 'secret',
            tokenExchange: exchange,
            redirectUri: 'app://cb',
            urlLauncher: (_) async => null,
            dio: mockDio,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws when neither clientSecret nor tokenExchange', () {
        expect(
          () => StravaAuthManager(
            clientId: 'id',
            redirectUri: 'app://cb',
            urlLauncher: (_) async => null,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws when clientSecret is empty without tokenExchange', () {
        expect(
          () => StravaAuthManager(
            clientId: 'id',
            clientSecret: '',
            redirectUri: 'app://cb',
            urlLauncher: (_) async => null,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('tokenExchange', () {
      late MockStravaTokenExchange mockExchange;

      setUp(() {
        mockExchange = MockStravaTokenExchange();
      });

      test('authorize uses tokenExchange and does not call Dio', () async {
        final futureToken = StravaToken(
          accessToken: 'ex-at',
          refreshToken: 'ex-rt',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        when(
          () => mockExchange.exchangeAuthorizationCode(
            code: any(named: 'code'),
            codeVerifier: any(named: 'codeVerifier'),
            redirectUri: any(named: 'redirectUri'),
          ),
        ).thenAnswer((_) async => futureToken);

        final manager = StravaAuthManager(
          clientId: 'test-client-id',
          tokenExchange: mockExchange,
          redirectUri: 'com.test.app://callback',
          urlLauncher: (url) async {
            final state = url.queryParameters['state'] ?? '';
            final redirect = url.queryParameters['redirect_uri'];
            return '$redirect?code=ex-code&state=$state';
          },
          dio: mockDio,
        );

        final token = await manager.authorize();

        expect(token, same(futureToken));
        verifyNever(
          () => mockDio.postUri<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        );
        verify(
          () => mockExchange.exchangeAuthorizationCode(
            code: 'ex-code',
            codeVerifier: any(named: 'codeVerifier'),
            redirectUri: 'com.test.app://callback',
          ),
        ).called(1);
      });

      test('refreshToken uses tokenExchange', () async {
        final newToken = StravaToken(
          accessToken: 'r-at',
          refreshToken: 'r-rt',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        when(
          () => mockExchange.refreshAccessToken(
            refreshToken: any(named: 'refreshToken'),
          ),
        ).thenAnswer((_) async => newToken);

        final manager = StravaAuthManager(
          clientId: 'test-client-id',
          tokenExchange: mockExchange,
          redirectUri: 'com.test.app://callback',
          urlLauncher: (_) async => null,
          dio: mockDio,
        );

        final existing = StravaToken(
          accessToken: 'old',
          refreshToken: 'rt-1',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        final out = await manager.refreshToken(existing);

        expect(out, same(newToken));
        verify(
          () => mockExchange.refreshAccessToken(refreshToken: 'rt-1'),
        ).called(1);
        verifyNever(
          () => mockDio.postUri<dynamic>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        );
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
        StravaToken? callbackToken = StravaToken(
          accessToken: 'sentinel',
          refreshToken: 'sentinel',
          expiresAt: DateTime.now(),
        );
        var callCount = 0;

        final manager = StravaAuthManager(
          clientId: 'test-client-id',
          clientSecret: 'test-client-secret',
          redirectUri: 'com.test.app://callback',
          urlLauncher: (_) async => null,
          dio: mockDio,
          initialToken: StravaToken(
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

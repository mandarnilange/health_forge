import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_strava/src/api/strava_api_client.dart';
import 'package:health_forge_strava/src/auth/strava_auth_manager.dart';
import 'package:health_forge_strava/src/auth/strava_token.dart';
import 'package:mocktail/mocktail.dart';

class MockStravaAuthManager extends Mock implements StravaAuthManager {}

class MockDio extends Mock implements Dio {
  @override
  Interceptors get interceptors => Interceptors();
}

void main() {
  late StravaApiClient apiClient;
  late MockStravaAuthManager mockAuthManager;
  late MockDio mockDio;

  setUp(() {
    mockAuthManager = MockStravaAuthManager();
    mockDio = MockDio();

    when(() => mockAuthManager.currentToken).thenReturn(
      StravaToken(
        accessToken: 'test-token',
        refreshToken: 'test-refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );

    // perPage=3 so fixture with 2 items terminates pagination (2 < 3)
    apiClient = StravaApiClient(
      authManager: mockAuthManager,
      dio: mockDio,
      perPage: 3,
    );
  });

  setUpAll(() {
    registerFallbackValue(RequestOptions());
  });

  group('StravaApiClient', () {
    group('fetchActivities', () {
      test('returns parsed activity list', () async {
        final file = File('test/fixtures/activities_response.json');
        final json = jsonDecode(file.readAsStringSync());

        when(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: json,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final response = await apiClient.fetchActivities(
          after: DateTime.utc(2024, 1, 15),
          before: DateTime.utc(2024, 1, 16),
        );

        expect(response.activities, hasLength(2));
        expect(response.activities.first.name, 'Morning Run');
      });

      test('handles page-based pagination', () async {
        final file = File('test/fixtures/activities_response.json');
        final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;

        // Use perPage=2 so first page (2 items) triggers next page
        apiClient = StravaApiClient(
          authManager: mockAuthManager,
          dio: mockDio,
          perPage: 2,
        );

        var callCount = 0;
        when(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            // Return 2 items (== perPage), so pagination continues
            return Response(
              data: json,
              statusCode: 200,
              requestOptions: RequestOptions(),
            );
          }
          // Return 1 item (< perPage), pagination stops
          return Response(
            data: [json.first],
            statusCode: 200,
            requestOptions: RequestOptions(),
          );
        });

        final response = await apiClient.fetchActivities(
          after: DateTime.utc(2024, 1, 15),
          before: DateTime.utc(2024, 1, 16),
        );

        expect(response.activities, hasLength(3));
        expect(callCount, 2);
      });

      test('stops pagination when page returns empty', () async {
        when(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: <dynamic>[],
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final response = await apiClient.fetchActivities(
          after: DateTime.utc(2024, 1, 15),
          before: DateTime.utc(2024, 1, 16),
        );

        expect(response.activities, isEmpty);
      });

      test('sends epoch seconds as after/before params', () async {
        Map<String, dynamic>? capturedParams;

        when(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((invocation) async {
          capturedParams = invocation.namedArguments[#queryParameters]
              as Map<String, dynamic>;
          return Response(
            data: <dynamic>[],
            statusCode: 200,
            requestOptions: RequestOptions(),
          );
        });

        final after = DateTime.utc(2024, 1, 15);
        final before = DateTime.utc(2024, 1, 16);

        await apiClient.fetchActivities(after: after, before: before);

        expect(
          capturedParams!['after'],
          after.millisecondsSinceEpoch ~/ 1000,
        );
        expect(
          capturedParams!['before'],
          before.millisecondsSinceEpoch ~/ 1000,
        );
      });
    });

    group('fetchActivityDetail', () {
      test('returns parsed activity detail', () async {
        final file = File('test/fixtures/activity_detail_response.json');
        final json = jsonDecode(file.readAsStringSync());

        when(
          () => mockDio.get<dynamic>(any()),
        ).thenAnswer(
          (_) async => Response(
            data: json,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final response =
            await apiClient.fetchActivityDetail(activityId: 12345678901);

        expect(response.id, 12345678901);
        expect(response.name, 'Morning Run');
        expect(response.segmentEfforts, hasLength(1));
      });
    });

    group('fetchActivityStreams', () {
      test('returns parsed streams response', () async {
        final file = File('test/fixtures/streams_response.json');
        final json = jsonDecode(file.readAsStringSync());

        when(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: json,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final response =
            await apiClient.fetchActivityStreams(activityId: 12345678901);

        expect(response.streams, hasLength(2));
        expect(response.dataForType('heartrate'), isNotNull);
      });
    });
  });
}

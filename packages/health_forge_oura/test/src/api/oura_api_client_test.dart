import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_oura/src/api/oura_api_client.dart';
import 'package:health_forge_oura/src/auth/oura_auth_manager.dart';
import 'package:health_forge_oura/src/auth/oura_token.dart';
import 'package:mocktail/mocktail.dart';

class MockOuraAuthManager extends Mock implements OuraAuthManager {}

class MockDio extends Mock implements Dio {
  @override
  Interceptors get interceptors => Interceptors();
}

void main() {
  late OuraApiClient apiClient;
  late MockOuraAuthManager mockAuthManager;
  late MockDio mockDio;

  setUp(() {
    mockAuthManager = MockOuraAuthManager();
    mockDio = MockDio();

    when(() => mockAuthManager.currentToken).thenReturn(
      OuraToken(
        accessToken: 'test-token',
        refreshToken: 'test-refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );

    apiClient = OuraApiClient(
      authManager: mockAuthManager,
      dio: mockDio,
    );
  });

  setUpAll(() {
    registerFallbackValue(RequestOptions());
  });

  group('OuraApiClient', () {
    Response<dynamic> makeResponse(String fixturePath, {String? nextToken}) {
      final file = File(fixturePath);
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      if (nextToken != null) {
        json['next_token'] = nextToken;
      }
      return Response(
        data: json,
        statusCode: 200,
        requestOptions: RequestOptions(),
      );
    }

    group('fetchSleep', () {
      test('returns parsed sleep response', () async {
        when(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => makeResponse('test/fixtures/sleep_response.json'),
        );

        final response = await apiClient.fetchSleep(
          startDate: '2024-01-15',
          endDate: '2024-01-16',
        );

        expect(response.data, hasLength(1));
        expect(response.data.first.id, 'sleep_001');
      });

      test('handles pagination', () async {
        var callCount = 0;
        when(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return makeResponse(
              'test/fixtures/sleep_response.json',
              nextToken: 'page2',
            );
          }
          return makeResponse('test/fixtures/sleep_response.json');
        });

        final response = await apiClient.fetchSleep(
          startDate: '2024-01-15',
          endDate: '2024-01-16',
        );

        // Should have 2 items (1 from each page)
        expect(response.data, hasLength(2));
        expect(callCount, 2);
      });
    });

    group('fetchDailySleep', () {
      test('returns parsed daily sleep response', () async {
        when(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => makeResponse('test/fixtures/daily_sleep_response.json'),
        );

        final response = await apiClient.fetchDailySleep(
          startDate: '2024-01-15',
          endDate: '2024-01-16',
        );

        expect(response.data, hasLength(1));
        expect(response.data.first.score, 85);
      });
    });

    group('fetchDailyActivity', () {
      test('returns parsed daily activity response', () async {
        when(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async =>
              makeResponse('test/fixtures/daily_activity_response.json'),
        );

        final response = await apiClient.fetchDailyActivity(
          startDate: '2024-01-15',
          endDate: '2024-01-16',
        );

        expect(response.data, hasLength(1));
        expect(response.data.first.steps, 8523);
      });
    });

    group('fetchHeartRate', () {
      test('returns parsed heart rate response', () async {
        when(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => makeResponse('test/fixtures/heart_rate_response.json'),
        );

        final response = await apiClient.fetchHeartRate(
          startDate: '2024-01-15',
          endDate: '2024-01-16',
        );

        expect(response.data, hasLength(2));
        expect(response.data.first.bpm, 72);
      });
    });

    group('fetchDailyReadiness', () {
      test('returns parsed daily readiness response', () async {
        when(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async =>
              makeResponse('test/fixtures/daily_readiness_response.json'),
        );

        final response = await apiClient.fetchDailyReadiness(
          startDate: '2024-01-15',
          endDate: '2024-01-16',
        );

        expect(response.data, hasLength(1));
        expect(response.data.first.score, 82);
      });
    });

    group('fetchDailyStress', () {
      test('returns parsed daily stress response', () async {
        when(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => makeResponse('test/fixtures/daily_stress_response.json'),
        );

        final response = await apiClient.fetchDailyStress(
          startDate: '2024-01-15',
          endDate: '2024-01-16',
        );

        expect(response.data, hasLength(1));
        expect(response.data.first.daySummary, 'restored');
      });
    });

    group('fetchDailySpo2', () {
      test('returns parsed daily SpO2 response', () async {
        when(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => makeResponse('test/fixtures/daily_spo2_response.json'),
        );

        final response = await apiClient.fetchDailySpo2(
          startDate: '2024-01-15',
          endDate: '2024-01-16',
        );

        expect(response.data, hasLength(1));
        expect(response.data.first.spo2Percentage!.average, 97.5);
      });
    });
  });
}

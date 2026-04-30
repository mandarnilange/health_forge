import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_oura/src/api/oura_api_endpoints.dart';

void main() {
  group('OuraApiEndpoints', () {
    test('baseUrl points to Oura API', () {
      expect(OuraApiEndpoints.baseUrl, 'https://api.ouraring.com');
    });

    test('apiVersion is v2', () {
      expect(OuraApiEndpoints.apiVersion, 'v2');
    });

    test('authorizeUrl points to Oura cloud OAuth', () {
      expect(
        OuraApiEndpoints.authorizeUrl,
        'https://cloud.ouraring.com/oauth/authorize',
      );
    });

    test('tokenUrl points to Oura API OAuth token', () {
      expect(
        OuraApiEndpoints.tokenUrl,
        'https://api.ouraring.com/oauth/token',
      );
    });

    test('sleep endpoint', () {
      expect(OuraApiEndpoints.sleep, '/v2/usercollection/sleep');
    });

    test('dailySleep endpoint', () {
      expect(OuraApiEndpoints.dailySleep, '/v2/usercollection/daily_sleep');
    });

    test('dailyActivity endpoint', () {
      expect(
        OuraApiEndpoints.dailyActivity,
        '/v2/usercollection/daily_activity',
      );
    });

    test('heartRate endpoint', () {
      expect(OuraApiEndpoints.heartRate, '/v2/usercollection/heartrate');
    });

    test('dailyReadiness endpoint', () {
      expect(
        OuraApiEndpoints.dailyReadiness,
        '/v2/usercollection/daily_readiness',
      );
    });

    test('dailyStress endpoint', () {
      expect(OuraApiEndpoints.dailyStress, '/v2/usercollection/daily_stress');
    });

    test('dailySpo2 endpoint', () {
      expect(OuraApiEndpoints.dailySpo2, '/v2/usercollection/daily_spo2');
    });

    test('all data endpoints start with /v2/usercollection/', () {
      const endpoints = [
        OuraApiEndpoints.sleep,
        OuraApiEndpoints.dailySleep,
        OuraApiEndpoints.dailyActivity,
        OuraApiEndpoints.heartRate,
        OuraApiEndpoints.dailyReadiness,
        OuraApiEndpoints.dailyStress,
        OuraApiEndpoints.dailySpo2,
      ];

      for (final endpoint in endpoints) {
        expect(
          endpoint.startsWith('/v2/usercollection/'),
          isTrue,
          reason: '$endpoint should start with /v2/usercollection/',
        );
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_strava/src/auth/strava_token.dart';

void main() {
  group('StravaToken', () {
    test('isExpired returns false for future expiry', () {
      final token = StravaToken(
        accessToken: 'at',
        refreshToken: 'rt',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(token.isExpired, isFalse);
    });

    test('isExpired returns true for past expiry', () {
      final token = StravaToken(
        accessToken: 'at',
        refreshToken: 'rt',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(token.isExpired, isTrue);
    });

    test('stores access token', () {
      final token = StravaToken(
        accessToken: 'my-access-token',
        refreshToken: 'rt',
        expiresAt: DateTime.now(),
      );
      expect(token.accessToken, 'my-access-token');
    });

    test('stores refresh token', () {
      final token = StravaToken(
        accessToken: 'at',
        refreshToken: 'my-refresh-token',
        expiresAt: DateTime.now(),
      );
      expect(token.refreshToken, 'my-refresh-token');
    });

    group('serialization', () {
      test('toJson produces expected map', () {
        final expiresAt = DateTime.utc(2026, 6, 15, 12);
        final token = StravaToken(
          accessToken: 'at',
          refreshToken: 'rt',
          expiresAt: expiresAt,
        );

        final json = token.toJson();

        expect(json['accessToken'], 'at');
        expect(json['refreshToken'], 'rt');
        expect(json['expiresAt'], expiresAt.toIso8601String());
      });

      test('fromJson restores token', () {
        final json = {
          'accessToken': 'at',
          'refreshToken': 'rt',
          'expiresAt': '2026-06-15T12:00:00.000Z',
        };

        final token = StravaToken.fromJson(json);

        expect(token.accessToken, 'at');
        expect(token.refreshToken, 'rt');
        expect(token.expiresAt, DateTime.utc(2026, 6, 15, 12));
      });

      test('toJson/fromJson round-trip preserves data', () {
        final original = StravaToken(
          accessToken: 'access-abc',
          refreshToken: 'refresh-xyz',
          expiresAt: DateTime.utc(2026, 12, 31, 23, 59, 59),
        );

        final restored = StravaToken.fromJson(original.toJson());

        expect(restored.accessToken, original.accessToken);
        expect(restored.refreshToken, original.refreshToken);
        expect(restored.expiresAt, original.expiresAt);
      });
    });
  });
}

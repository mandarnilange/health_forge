import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_oura/src/auth/oura_token.dart';

void main() {
  group('OuraToken', () {
    test('construction stores all fields', () {
      final expiresAt = DateTime(2026, 12, 31);
      final token = OuraToken(
        accessToken: 'access-abc',
        refreshToken: 'refresh-xyz',
        expiresAt: expiresAt,
      );

      expect(token.accessToken, 'access-abc');
      expect(token.refreshToken, 'refresh-xyz');
      expect(token.expiresAt, expiresAt);
    });

    test('isExpired returns false when expiresAt is in the future', () {
      final token = OuraToken(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(token.isExpired, isFalse);
    });

    test('isExpired returns true when expiresAt is in the past', () {
      final token = OuraToken(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(token.isExpired, isTrue);
    });

    test('accessToken field returns provided value', () {
      final token = OuraToken(
        accessToken: 'my-secret-token',
        refreshToken: 'refresh',
        expiresAt: DateTime(2026, 6),
      );

      expect(token.accessToken, 'my-secret-token');
    });

    test('refreshToken field returns provided value', () {
      final token = OuraToken(
        accessToken: 'access',
        refreshToken: 'my-refresh-token',
        expiresAt: DateTime(2026, 6),
      );

      expect(token.refreshToken, 'my-refresh-token');
    });

    group('serialization', () {
      test('toJson produces expected map', () {
        final expiresAt = DateTime.utc(2026, 6, 15, 12);
        final token = OuraToken(
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

        final token = OuraToken.fromJson(json);

        expect(token.accessToken, 'at');
        expect(token.refreshToken, 'rt');
        expect(token.expiresAt, DateTime.utc(2026, 6, 15, 12));
      });

      test('toJson/fromJson round-trip preserves data', () {
        final original = OuraToken(
          accessToken: 'access-abc',
          refreshToken: 'refresh-xyz',
          expiresAt: DateTime.utc(2026, 12, 31, 23, 59, 59),
        );

        final restored = OuraToken.fromJson(original.toJson());

        expect(restored.accessToken, original.accessToken);
        expect(restored.refreshToken, original.refreshToken);
        expect(restored.expiresAt, original.expiresAt);
      });
    });
  });
}

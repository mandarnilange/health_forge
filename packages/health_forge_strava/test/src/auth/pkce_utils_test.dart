import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_strava/src/auth/pkce_utils.dart';

void main() {
  group('PkceUtils', () {
    group('generateCodeVerifier', () {
      test('default length is 128', () {
        final verifier = PkceUtils.generateCodeVerifier();
        expect(verifier.length, 128);
      });

      test('custom length is respected', () {
        final verifier = PkceUtils.generateCodeVerifier(length: 43);
        expect(verifier.length, 43);
      });

      test('only contains unreserved characters', () {
        final verifier = PkceUtils.generateCodeVerifier();
        expect(
          verifier,
          matches(RegExp(r'^[A-Za-z0-9\-._~]+$')),
        );
      });

      test('generates unique verifiers', () {
        final a = PkceUtils.generateCodeVerifier();
        final b = PkceUtils.generateCodeVerifier();
        expect(a, isNot(equals(b)));
      });
    });

    group('generateCodeChallenge', () {
      test('produces a non-empty base64url string', () {
        final verifier = PkceUtils.generateCodeVerifier();
        final challenge = PkceUtils.generateCodeChallenge(verifier);
        expect(challenge, isNotEmpty);
        expect(challenge, isNot(contains('=')));
      });

      test('is deterministic for the same verifier', () {
        const verifier = 'test-verifier-string';
        final a = PkceUtils.generateCodeChallenge(verifier);
        final b = PkceUtils.generateCodeChallenge(verifier);
        expect(a, equals(b));
      });

      test('produces different challenges for different verifiers', () {
        final a = PkceUtils.generateCodeChallenge('verifier-a');
        final b = PkceUtils.generateCodeChallenge('verifier-b');
        expect(a, isNot(equals(b)));
      });
    });
  });
}

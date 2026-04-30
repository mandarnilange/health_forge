import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_oura/src/auth/pkce_utils.dart';

void main() {
  group('PkceUtils', () {
    group('generateCodeVerifier', () {
      test('generates verifier with default length of 128', () {
        final verifier = PkceUtils.generateCodeVerifier();
        expect(verifier.length, 128);
      });

      test('generates verifier with custom length', () {
        final verifier = PkceUtils.generateCodeVerifier(length: 43);
        expect(verifier.length, 43);
      });

      test('uses only valid unreserved characters', () {
        final verifier = PkceUtils.generateCodeVerifier();
        final validChars = RegExp(r'^[A-Za-z0-9\-._~]+$');
        expect(validChars.hasMatch(verifier), isTrue);
      });

      test('generates different verifiers on successive calls', () {
        final a = PkceUtils.generateCodeVerifier();
        final b = PkceUtils.generateCodeVerifier();
        expect(a, isNot(equals(b)));
      });
    });

    group('generateCodeChallenge', () {
      test('is deterministic for the same verifier', () {
        const verifier = 'test-verifier-value';
        final challengeA = PkceUtils.generateCodeChallenge(verifier);
        final challengeB = PkceUtils.generateCodeChallenge(verifier);
        expect(challengeA, equals(challengeB));
      });

      test('differs for different verifiers', () {
        final challengeA = PkceUtils.generateCodeChallenge('verifier-one');
        final challengeB = PkceUtils.generateCodeChallenge('verifier-two');
        expect(challengeA, isNot(equals(challengeB)));
      });

      test('produces base64url without padding', () {
        final challenge = PkceUtils.generateCodeChallenge('some-verifier');
        expect(challenge, isNot(contains('=')));
        expect(challenge, isNot(contains('+')));
        expect(challenge, isNot(contains('/')));
      });

      test('produces a 43-character challenge for SHA-256', () {
        // SHA-256 produces 32 bytes -> base64url = ceil(32*4/3) = 43 chars
        // (without padding)
        final challenge = PkceUtils.generateCodeChallenge('any-verifier');
        expect(challenge.length, 43);
      });
    });
  });
}

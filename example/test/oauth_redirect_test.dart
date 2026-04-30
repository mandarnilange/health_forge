import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_example/oauth_redirect.dart';

void main() {
  group('normalizeOAuthRedirectPath', () {
    test('empty stays empty', () {
      expect(normalizeOAuthRedirectPath(''), '');
    });

    test('adds leading slash when missing', () {
      expect(normalizeOAuthRedirectPath('callback'), '/callback');
    });

    test('preserves leading slash', () {
      expect(normalizeOAuthRedirectPath('/callback'), '/callback');
    });
  });

  group('oauthRedirectMatches', () {
    final expected = Uri.parse('myapp://oauth/callback');

    test('matches exact redirect', () {
      expect(
        oauthRedirectMatches(Uri.parse('myapp://oauth/callback'), expected),
        isTrue,
      );
    });

    test('scheme comparison is case insensitive', () {
      expect(
        oauthRedirectMatches(Uri.parse('MYAPP://oauth/callback'), expected),
        isTrue,
      );
    });

    test('host comparison is case insensitive', () {
      expect(
        oauthRedirectMatches(Uri.parse('myapp://OAUTH/callback'), expected),
        isTrue,
      );
    });

    test('path normalization matches', () {
      expect(
        oauthRedirectMatches(Uri.parse('myapp://oauth/callback'), expected),
        isTrue,
      );
    });

    test('wrong scheme rejects', () {
      expect(
        oauthRedirectMatches(Uri.parse('other://oauth/callback'), expected),
        isFalse,
      );
    });

    test('wrong host rejects', () {
      expect(
        oauthRedirectMatches(Uri.parse('myapp://evil/callback'), expected),
        isFalse,
      );
    });

    test('wrong port rejects', () {
      expect(
        oauthRedirectMatches(
          Uri.parse('myapp://oauth:8080/callback'),
          expected,
        ),
        isFalse,
      );
    });
  });
}

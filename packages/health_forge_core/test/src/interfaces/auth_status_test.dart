import 'package:health_forge_core/src/interfaces/auth_status.dart';
import 'package:test/test.dart';

void main() {
  group('AuthStatus', () {
    test('has connected value', () {
      expect(AuthStatus.connected, isNotNull);
    });

    test('has disconnected value', () {
      expect(AuthStatus.disconnected, isNotNull);
    });

    test('has expired value', () {
      expect(AuthStatus.expired, isNotNull);
    });

    test('contains exactly 3 values', () {
      expect(AuthStatus.values, hasLength(3));
    });
  });
}

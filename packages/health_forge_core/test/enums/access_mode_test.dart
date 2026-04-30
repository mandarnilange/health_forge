import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('AccessMode', () {
    test('has all expected values', () {
      expect(AccessMode.values, hasLength(3));
      expect(
        AccessMode.values,
        containsAll([
          AccessMode.read,
          AccessMode.write,
          AccessMode.readWrite,
        ]),
      );
    });

    test('JSON round-trip', () {
      for (final value in AccessMode.values) {
        expect(AccessMode.values.byName(value.name), equals(value));
      }
    });
  });
}

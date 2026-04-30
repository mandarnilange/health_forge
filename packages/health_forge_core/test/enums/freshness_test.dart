import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('Freshness', () {
    test('has all expected values', () {
      expect(Freshness.values, hasLength(2));
      expect(
        Freshness.values,
        containsAll([
          Freshness.live,
          Freshness.cached,
        ]),
      );
    });

    test('JSON round-trip', () {
      for (final value in Freshness.values) {
        expect(Freshness.values.byName(value.name), equals(value));
      }
    });
  });
}

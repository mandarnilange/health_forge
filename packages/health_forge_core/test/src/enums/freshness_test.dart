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

    test('toString includes value name', () {
      expect(Freshness.live.toString(), contains('live'));
      expect(Freshness.cached.toString(), contains('cached'));
    });

    test('byName round-trip', () {
      for (final value in Freshness.values) {
        expect(Freshness.values.byName(value.name), equals(value));
      }
    });
  });
}

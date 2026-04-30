import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('ConflictStrategy', () {
    test('has all expected values', () {
      expect(ConflictStrategy.values, hasLength(5));
      expect(
        ConflictStrategy.values,
        containsAll([
          ConflictStrategy.priorityBased,
          ConflictStrategy.keepAll,
          ConflictStrategy.average,
          ConflictStrategy.mostGranular,
          ConflictStrategy.custom,
        ]),
      );
    });

    test('JSON round-trip', () {
      for (final value in ConflictStrategy.values) {
        expect(
          ConflictStrategy.values.byName(value.name),
          equals(value),
        );
      }
    });
  });
}

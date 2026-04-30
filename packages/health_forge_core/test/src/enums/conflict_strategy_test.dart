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

    test('toString includes value name', () {
      expect(
        ConflictStrategy.priorityBased.toString(),
        contains('priorityBased'),
      );
      expect(ConflictStrategy.keepAll.toString(), contains('keepAll'));
      expect(ConflictStrategy.average.toString(), contains('average'));
      expect(
        ConflictStrategy.mostGranular.toString(),
        contains('mostGranular'),
      );
      expect(ConflictStrategy.custom.toString(), contains('custom'));
    });

    test('byName round-trip', () {
      for (final value in ConflictStrategy.values) {
        expect(ConflictStrategy.values.byName(value.name), equals(value));
      }
    });
  });
}

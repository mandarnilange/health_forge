import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('DataOrigin', () {
    test('has all expected values', () {
      expect(DataOrigin.values, hasLength(5));
      expect(
        DataOrigin.values,
        containsAll([
          DataOrigin.native_,
          DataOrigin.mapped,
          DataOrigin.derived,
          DataOrigin.estimated,
          DataOrigin.extracted,
        ]),
      );
    });

    test('toString includes value name', () {
      expect(DataOrigin.native_.toString(), contains('native_'));
      expect(DataOrigin.mapped.toString(), contains('mapped'));
      expect(DataOrigin.derived.toString(), contains('derived'));
      expect(DataOrigin.estimated.toString(), contains('estimated'));
      expect(DataOrigin.extracted.toString(), contains('extracted'));
    });

    test('byName round-trip', () {
      for (final value in DataOrigin.values) {
        expect(DataOrigin.values.byName(value.name), equals(value));
      }
    });
  });
}

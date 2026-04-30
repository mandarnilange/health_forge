import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('DataProvider', () {
    test('has all expected values', () {
      expect(DataProvider.values, hasLength(5));
      expect(
        DataProvider.values,
        containsAll([
          DataProvider.apple,
          DataProvider.googleHealthConnect,
          DataProvider.strava,
          DataProvider.oura,
          DataProvider.garmin,
        ]),
      );
    });

    test('JSON round-trip', () {
      for (final value in DataProvider.values) {
        expect(DataProvider.values.byName(value.name), equals(value));
      }
    });
  });
}

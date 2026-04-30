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

    test('toString includes value name', () {
      expect(DataProvider.apple.toString(), contains('apple'));
      expect(
        DataProvider.googleHealthConnect.toString(),
        contains('googleHealthConnect'),
      );
      expect(DataProvider.strava.toString(), contains('strava'));
      expect(DataProvider.oura.toString(), contains('oura'));
      expect(DataProvider.garmin.toString(), contains('garmin'));
    });

    test('byName round-trip', () {
      for (final value in DataProvider.values) {
        expect(DataProvider.values.byName(value.name), equals(value));
      }
    });
  });
}

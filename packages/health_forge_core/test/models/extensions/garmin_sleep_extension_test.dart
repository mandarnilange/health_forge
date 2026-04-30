import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('GarminSleepExtension', () {
    test('constructs with all fields', () {
      final ext = GarminSleepExtension(
        bodyBatteryChange: 45,
        stressQualifier: 'low',
      );

      expect(ext.bodyBatteryChange, 45);
      expect(ext.stressQualifier, 'low');
    });

    test('constructs with null optional fields', () {
      final ext = GarminSleepExtension();

      expect(ext.bodyBatteryChange, isNull);
      expect(ext.stressQualifier, isNull);
    });

    test('typeKey equals garmin_sleep', () {
      final ext = GarminSleepExtension();

      expect(ext.typeKey, 'garmin_sleep');
    });

    test('JSON round-trip', () {
      final original = GarminSleepExtension(
        bodyBatteryChange: 45,
        stressQualifier: 'low',
      );

      final json = original.toJson();
      final restored = GarminSleepExtension.fromJson(json);

      expect(restored.bodyBatteryChange, original.bodyBatteryChange);
      expect(restored.stressQualifier, original.stressQualifier);
    });

    test('toJson produces correct map', () {
      final ext = GarminSleepExtension(
        bodyBatteryChange: 45,
        stressQualifier: 'low',
      );

      expect(ext.toJson(), {
        'bodyBatteryChange': 45,
        'stressQualifier': 'low',
      });
    });

    test('is a ProviderExtension', () {
      final ext = GarminSleepExtension();

      expect(ext, isA<ProviderExtension>());
    });
  });
}

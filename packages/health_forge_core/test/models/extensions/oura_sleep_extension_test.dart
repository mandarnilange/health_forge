import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('OuraSleepExtension', () {
    test('constructs with all fields', () {
      final ext = OuraSleepExtension(
        readinessScore: 85,
        temperatureDeviation: 0.3,
        readinessContributorSleep: 90,
      );

      expect(ext.readinessScore, 85);
      expect(ext.temperatureDeviation, 0.3);
      expect(ext.readinessContributorSleep, 90);
    });

    test('constructs with null optional fields', () {
      final ext = OuraSleepExtension();

      expect(ext.readinessScore, isNull);
      expect(ext.temperatureDeviation, isNull);
      expect(ext.readinessContributorSleep, isNull);
    });

    test('typeKey equals oura_sleep', () {
      final ext = OuraSleepExtension();

      expect(ext.typeKey, 'oura_sleep');
    });

    test('JSON round-trip', () {
      final original = OuraSleepExtension(
        readinessScore: 85,
        temperatureDeviation: 0.3,
        readinessContributorSleep: 90,
      );

      final json = original.toJson();
      final restored = OuraSleepExtension.fromJson(json);

      expect(restored.readinessScore, original.readinessScore);
      expect(restored.temperatureDeviation, original.temperatureDeviation);
      expect(
        restored.readinessContributorSleep,
        original.readinessContributorSleep,
      );
    });

    test('toJson produces correct map', () {
      final ext = OuraSleepExtension(
        readinessScore: 85,
        temperatureDeviation: 0.3,
        readinessContributorSleep: 90,
      );

      expect(ext.toJson(), {
        'readinessScore': 85,
        'temperatureDeviation': 0.3,
        'readinessContributorSleep': 90,
      });
    });

    test('is a ProviderExtension', () {
      final ext = OuraSleepExtension();

      expect(ext, isA<ProviderExtension>());
    });
  });
}

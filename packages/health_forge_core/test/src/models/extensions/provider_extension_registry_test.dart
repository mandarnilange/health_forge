import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderExtensionRegistry', () {
    setUp(ProviderExtensionRegistry.clear);

    test('register and retrieve extension', () {
      ProviderExtensionRegistry.register(
        'oura_sleep',
        OuraSleepExtension.fromJson,
      );

      final ext = ProviderExtensionRegistry.fromJson('oura_sleep', {
        'readinessScore': 85,
      });

      expect(ext, isA<OuraSleepExtension>());
      expect((ext! as OuraSleepExtension).readinessScore, 85);
    });

    test('unknown typeKey returns null', () {
      final ext = ProviderExtensionRegistry.fromJson('unknown', {});

      expect(ext, isNull);
    });

    test('registerDefaults registers all three built-in providers', () {
      ProviderExtensionRegistry.registerDefaults();

      expect(
        ProviderExtensionRegistry.fromJson('oura_sleep', {}),
        isA<OuraSleepExtension>(),
      );
      expect(
        ProviderExtensionRegistry.fromJson('strava_workout', {}),
        isA<StravaWorkoutExtension>(),
      );
      expect(
        ProviderExtensionRegistry.fromJson('garmin_sleep', {}),
        isA<GarminSleepExtension>(),
      );
    });

    test('clear removes all registered factories', () {
      ProviderExtensionRegistry.registerDefaults();
      ProviderExtensionRegistry.clear();

      expect(ProviderExtensionRegistry.fromJson('oura_sleep', {}), isNull);
      expect(
        ProviderExtensionRegistry.fromJson('strava_workout', {}),
        isNull,
      );
      expect(ProviderExtensionRegistry.fromJson('garmin_sleep', {}), isNull);
    });
  });
}

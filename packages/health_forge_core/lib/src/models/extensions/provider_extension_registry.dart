import 'package:health_forge_core/health_forge_core.dart';

/// Registry that maps type keys to [ProviderExtension] factories for
/// polymorphic JSON deserialization.
class ProviderExtensionRegistry {
  static final Map<String, ProviderExtension Function(Map<String, dynamic>)>
  _factories = {};

  /// Registers a factory for the given [typeKey].
  static void register(
    String typeKey,
    ProviderExtension Function(Map<String, dynamic>) factory,
  ) {
    _factories[typeKey] = factory;
  }

  /// Looks up and invokes the factory for [typeKey], or returns `null`.
  static ProviderExtension? fromJson(
    String typeKey,
    Map<String, dynamic> json,
  ) {
    return _factories[typeKey]?.call(json);
  }

  /// Registers factories for all built-in provider extensions.
  static void registerDefaults() {
    register('oura_sleep', OuraSleepExtension.fromJson);
    register('strava_workout', StravaWorkoutExtension.fromJson);
    register('garmin_sleep', GarminSleepExtension.fromJson);
  }

  /// Removes all registered factories. Useful for test isolation.
  static void clear() {
    _factories.clear();
  }
}

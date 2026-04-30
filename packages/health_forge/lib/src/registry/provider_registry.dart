import 'package:health_forge_core/health_forge_core.dart';

/// Registry for managing health data providers.
class ProviderRegistry {
  final Map<DataProvider, HealthProvider> _providers = {};

  /// Registers a [provider]. Throws [StateError] if already registered.
  void register(HealthProvider provider) {
    final type = provider.providerType;
    if (_providers.containsKey(type)) {
      throw StateError('Provider $type is already registered');
    }
    _providers[type] = provider;
  }

  /// Unregisters the provider for the given [type].
  void unregister(DataProvider type) {
    _providers.remove(type);
  }

  /// Returns the provider for [type], or null if not registered.
  HealthProvider? provider(DataProvider type) => _providers[type];

  /// Returns all registered providers.
  List<HealthProvider> get all => List.unmodifiable(_providers.values);

  /// Returns providers that support the given [metric].
  List<HealthProvider> supporting(MetricType metric) {
    return _providers.values
        .where((p) => p.capabilities.supports(metric))
        .toList();
  }

  /// Whether a provider of [type] is registered.
  bool isRegistered(DataProvider type) => _providers.containsKey(type);
}

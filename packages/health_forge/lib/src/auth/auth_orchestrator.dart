import 'package:health_forge/src/registry/provider_registry.dart';
import 'package:health_forge_core/health_forge_core.dart';

/// Orchestrates authorization across all registered providers.
class AuthOrchestrator {
  /// Creates an [AuthOrchestrator] backed by the given [registry].
  AuthOrchestrator({required ProviderRegistry registry}) : _registry = registry;

  final ProviderRegistry _registry;

  /// Authorizes a single [provider]. Returns error if not registered.
  Future<AuthResult> authorize(DataProvider provider) async {
    final p = _registry.provider(provider);
    if (p == null) {
      return AuthResult.error(
        'Provider ${provider.name} is not registered',
      );
    }
    return p.authorize();
  }

  /// Deauthorizes a single [provider]. No-op if not registered.
  Future<void> deauthorize(DataProvider provider) async {
    final p = _registry.provider(provider);
    if (p == null) return;
    await p.deauthorize();
  }

  /// Authorizes all registered providers, returning results by provider.
  Future<Map<DataProvider, AuthResult>> authorizeAll() async {
    final results = <DataProvider, AuthResult>{};
    for (final p in _registry.all) {
      results[p.providerType] = await p.authorize();
    }
    return results;
  }

  /// Checks authorization status of all registered providers.
  Future<Map<DataProvider, bool>> checkAll() async {
    final results = <DataProvider, bool>{};
    for (final p in _registry.all) {
      results[p.providerType] = await p.isAuthorized();
    }
    return results;
  }

  /// Checks if a specific [provider] is authorized.
  /// Returns false if not registered.
  Future<bool> isAuthorized(DataProvider provider) async {
    final p = _registry.provider(provider);
    if (p == null) return false;
    return p.isAuthorized();
  }
}

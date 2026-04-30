import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:health_forge_core/health_forge_core.dart';

/// Secure storage for provider authentication tokens.
class TokenStore {
  /// Creates a [TokenStore] backed by the given secure [storage].
  TokenStore({required FlutterSecureStorage storage}) : _storage = storage;

  final FlutterSecureStorage _storage;

  static String _key(DataProvider provider) =>
      'health_forge_token_${provider.name}';

  /// Saves a [token] for the given [provider].
  Future<void> save(DataProvider provider, String token) =>
      _storage.write(key: _key(provider), value: token);

  /// Reads the token for the given [provider], or null if not found.
  Future<String?> read(DataProvider provider) =>
      _storage.read(key: _key(provider));

  /// Deletes the token for the given [provider].
  Future<void> delete(DataProvider provider) =>
      _storage.delete(key: _key(provider));

  /// Deletes all health_forge tokens without affecting other secure storage.
  Future<void> deleteAll() async {
    for (final provider in DataProvider.values) {
      await _storage.delete(key: _key(provider));
    }
  }
}

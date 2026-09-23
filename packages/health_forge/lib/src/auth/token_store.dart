import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:health_forge_core/health_forge_core.dart';

/// Thrown when [TokenStore.save] could not persist a token.
class TokenStoreException implements Exception {
  /// Creates an exception for a token that failed to save for [provider].
  const TokenStoreException(this.provider);

  /// The provider whose token could not be saved.
  final DataProvider provider;

  @override
  String toString() =>
      'TokenStoreException: token for ${provider.name} was not persisted';
}

/// Secure storage for provider authentication tokens.
class TokenStore {
  /// Creates a [TokenStore] backed by the given secure [storage].
  TokenStore({required FlutterSecureStorage storage}) : _storage = storage;

  final FlutterSecureStorage _storage;

  /// Value flutter_secure_storage returns on Android when `resetOnError`
  /// (the default) wiped all data after a failed operation.
  static const _resetSentinel = 'Data has been reset';

  static String _key(DataProvider provider) =>
      'health_forge_token_${provider.name}';

  /// Saves a [token] for the given [provider].
  ///
  /// Reads the value back to confirm it was stored, and throws a
  /// [TokenStoreException] if it wasn't. On Android, a failed write with
  /// `resetOnError` enabled wipes storage but still completes normally.
  Future<void> save(DataProvider provider, String token) async {
    await _storage.write(key: _key(provider), value: token);
    if (await _storage.read(key: _key(provider)) != token) {
      throw TokenStoreException(provider);
    }
  }

  /// Reads the token for the given [provider], or null if not found.
  ///
  /// Also returns null when the platform storage was reset after a failure,
  /// so the reset message is never mistaken for a token.
  Future<String?> read(DataProvider provider) async {
    final value = await _storage.read(key: _key(provider));
    return value == _resetSentinel ? null : value;
  }

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

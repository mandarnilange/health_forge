import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge/src/auth/token_store.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late TokenStore tokenStore;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    tokenStore = TokenStore(storage: mockStorage);
  });

  group('TokenStore', () {
    test('save writes token to secure storage', () async {
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await tokenStore.save(DataProvider.apple, 'test-token');

      verify(
        () => mockStorage.write(
          key: 'health_forge_token_apple',
          value: 'test-token',
        ),
      ).called(1);
    });

    test('read returns token from secure storage', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'stored-token');

      final token = await tokenStore.read(DataProvider.oura);

      expect(token, 'stored-token');
      verify(
        () => mockStorage.read(
          key: 'health_forge_token_oura',
        ),
      ).called(1);
    });

    test('read returns null when no token exists', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);

      final token = await tokenStore.read(DataProvider.strava);

      expect(token, isNull);
    });

    test('delete removes token from secure storage', () async {
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await tokenStore.delete(DataProvider.garmin);

      verify(
        () => mockStorage.delete(
          key: 'health_forge_token_garmin',
        ),
      ).called(1);
    });

    test('deleteAll removes only health_forge tokens', () async {
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await tokenStore.deleteAll();

      // Should delete each provider key individually
      for (final provider in DataProvider.values) {
        verify(
          () => mockStorage.delete(
            key: 'health_forge_token_${provider.name}',
          ),
        ).called(1);
      }

      // Should NOT call deleteAll on the underlying storage
      verifyNever(() => mockStorage.deleteAll());
    });
  });
}

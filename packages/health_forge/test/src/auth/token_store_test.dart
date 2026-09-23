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
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'test-token');

      await tokenStore.save(DataProvider.apple, 'test-token');

      verify(
        () => mockStorage.write(
          key: 'health_forge_token_apple',
          value: 'test-token',
        ),
      ).called(1);
    });

    test(
      'save throws TokenStoreException when the token was not persisted',
      () async {
        // On Android, a failed write with resetOnError wipes storage and
        // still completes normally, so save must verify the write.
        when(
          () => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockStorage.read(key: any(named: 'key')),
        ).thenAnswer((_) async => null);

        await expectLater(
          tokenStore.save(DataProvider.oura, 'test-token'),
          throwsA(
            isA<TokenStoreException>().having(
              (e) => e.provider,
              'provider',
              DataProvider.oura,
            ),
          ),
        );
      },
    );

    test('read returns token from secure storage', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'stored-token');

      final token = await tokenStore.read(DataProvider.oura);

      expect(token, 'stored-token');
      verify(() => mockStorage.read(key: 'health_forge_token_oura')).called(1);
    });

    test('read returns null when no token exists', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);

      final token = await tokenStore.read(DataProvider.strava);

      expect(token, isNull);
    });

    test(
      'read returns null when storage was reset after an Android failure',
      () async {
        // With resetOnError (the Android default), flutter_secure_storage
        // wipes its data after a failure and returns this sentinel string as
        // the value of the failed call.
        when(
          () => mockStorage.read(key: any(named: 'key')),
        ).thenAnswer((_) async => 'Data has been reset');

        final token = await tokenStore.read(DataProvider.oura);

        expect(token, isNull);
      },
    );

    test('delete removes token from secure storage', () async {
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await tokenStore.delete(DataProvider.garmin);

      verify(
        () => mockStorage.delete(key: 'health_forge_token_garmin'),
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
          () => mockStorage.delete(key: 'health_forge_token_${provider.name}'),
        ).called(1);
      }

      // Should NOT call deleteAll on the underlying storage
      verifyNever(() => mockStorage.deleteAll());
    });
  });
}

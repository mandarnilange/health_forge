import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('HeartRateVariability', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final later = DateTime.utc(2026, 3, 17, 11);

    HeartRateVariability createMinimal() => HeartRateVariability(
      id: 'hrv-1',
      provider: DataProvider.oura,
      providerRecordType: 'hrv',
      startTime: now,
      endTime: later,
      capturedAt: now,
      sdnnMilliseconds: 45,
    );

    HeartRateVariability createFull() => HeartRateVariability(
      id: 'hrv-2',
      provider: DataProvider.apple,
      providerRecordType: 'HKQuantityTypeIdentifierHeartRateVariabilitySDNN',
      startTime: now,
      endTime: later,
      timezone: 'Australia/Sydney',
      capturedAt: now,
      provenance: const Provenance(dataOrigin: DataOrigin.native_),
      freshness: Freshness.cached,
      extensions: const {'method': 'sdnn'},
      sdnnMilliseconds: 55.3,
      rmssdMilliseconds: 42.1,
    );

    HeartRateVariability createRmssdOnly() => HeartRateVariability(
      id: 'hrv-3',
      provider: DataProvider.googleHealthConnect,
      providerRecordType: 'HEART_RATE_VARIABILITY_RMSSD',
      startTime: now,
      endTime: later,
      capturedAt: now,
      rmssdMilliseconds: 42.1,
    );

    test('constructs with required fields only', () {
      final record = createMinimal();
      expect(record.sdnnMilliseconds, 45.0);
      expect(record.rmssdMilliseconds, isNull);
    });

    test('constructs with rmssd only (SDNN null, e.g. Health Connect)', () {
      final record = createRmssdOnly();
      expect(record.sdnnMilliseconds, isNull);
      expect(record.rmssdMilliseconds, 42.1);
    });

    test('rmssd-only record survives JSON round-trip', () {
      final record = createRmssdOnly();
      final restored = HeartRateVariability.fromJson(record.toJson());
      expect(restored, equals(record));
      expect(restored.sdnnMilliseconds, isNull);
      expect(restored.rmssdMilliseconds, 42.1);
    });

    test('throws when neither SDNN nor RMSSD is provided', () {
      expect(
        () => HeartRateVariability(
          id: 'hrv-invalid',
          provider: DataProvider.googleHealthConnect,
          providerRecordType: 'hrv',
          startTime: now,
          endTime: later,
          capturedAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('constructs with all fields including optionals', () {
      final record = createFull();
      expect(record.sdnnMilliseconds, 55.3);
      expect(record.rmssdMilliseconds, 42.1);
      expect(record.timezone, 'Australia/Sydney');
    });

    test('two identical instances are equal', () {
      expect(createMinimal(), equals(createMinimal()));
    });

    test('copyWith works correctly', () {
      final copy = createMinimal().copyWith(rmssdMilliseconds: 38);
      expect(copy.rmssdMilliseconds, 38.0);
      expect(copy.sdnnMilliseconds, 45.0);
    });

    test('JSON round-trip produces equal object', () {
      final record = createFull();
      final json = record.toJson();
      final restored = HeartRateVariability.fromJson(json);
      expect(restored, equals(record));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(HeartRateVariability.fromJson(decoded), equals(record));
    });

    test('envelope fields accessible via mixin', () {
      final record = createFull();
      expect(record.id, isNotEmpty);
      expect(record.provider, DataProvider.apple);
      expect(record.duration, const Duration(hours: 1));
    });

    test('default values are correct', () {
      final record = createMinimal();
      expect(record.freshness, Freshness.live);
      expect(record.extensions, isEmpty);
      expect(record.provenance, isNull);
    });
  });
}

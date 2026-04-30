import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

class _TestHealthRecord with HealthRecordMixin {
  _TestHealthRecord({
    required this.id,
    required this.provider,
    required this.providerRecordType,
    required this.startTime,
    required this.endTime,
    required this.capturedAt,
    this.timezone,
    this.provenance,
    this.freshness = Freshness.live,
    this.extensions = const {},
    this.providerRecordId,
  });

  @override
  final String id;

  @override
  final DataProvider provider;

  @override
  final String providerRecordType;

  @override
  final String? providerRecordId;

  @override
  final DateTime startTime;

  @override
  final DateTime endTime;

  @override
  final String? timezone;

  @override
  final DateTime capturedAt;

  @override
  final Provenance? provenance;

  @override
  final Freshness freshness;

  @override
  final Map<String, dynamic> extensions;
}

void main() {
  group('HealthRecordMixin', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final later = DateTime.utc(2026, 3, 17, 11);

    test('provides all envelope fields', () {
      final record = _TestHealthRecord(
        id: 'test-id-1',
        provider: DataProvider.apple,
        providerRecordType: 'HKQuantityTypeIdentifierHeartRate',
        providerRecordId: 'native-uuid-123',
        startTime: now,
        endTime: later,
        timezone: 'America/New_York',
        capturedAt: now,
        provenance: const Provenance(dataOrigin: DataOrigin.native_),
        freshness: Freshness.cached,
        extensions: const {'key': 'value'},
      );

      expect(record.id, 'test-id-1');
      expect(record.provider, DataProvider.apple);
      expect(record.providerRecordType, contains('HeartRate'));
      expect(record.providerRecordId, 'native-uuid-123');
      expect(record.startTime, now);
      expect(record.endTime, later);
      expect(record.timezone, 'America/New_York');
      expect(record.capturedAt, now);
      expect(record.provenance?.dataOrigin, DataOrigin.native_);
      expect(record.freshness, Freshness.cached);
      expect(record.extensions, {'key': 'value'});
    });

    test('duration returns difference between end and start', () {
      final record = _TestHealthRecord(
        id: 'test-id-2',
        provider: DataProvider.oura,
        providerRecordType: 'sleep',
        startTime: now,
        endTime: later,
        capturedAt: now,
      );

      expect(record.duration, const Duration(hours: 1));
    });

    test('allows null optional fields', () {
      final record = _TestHealthRecord(
        id: 'test-id-3',
        provider: DataProvider.strava,
        providerRecordType: 'activity',
        startTime: now,
        endTime: later,
        capturedAt: now,
      );

      expect(record.providerRecordId, isNull);
      expect(record.timezone, isNull);
      expect(record.provenance, isNull);
      expect(record.freshness, Freshness.live);
      expect(record.extensions, isEmpty);
    });

    test('metricType getter works on concrete HeartRateSample', () {
      final sample = HeartRateSample(
        id: 'hr-1',
        provider: DataProvider.apple,
        providerRecordType: 'heartRate',
        startTime: now,
        endTime: now.add(const Duration(minutes: 1)),
        capturedAt: now,
        beatsPerMinute: 72,
      );

      expect(sample, isA<HealthRecordMixin>());
      expect(sample.id, 'hr-1');
      expect(sample.provider, DataProvider.apple);
      expect(sample.beatsPerMinute, 72);
    });
  });
}

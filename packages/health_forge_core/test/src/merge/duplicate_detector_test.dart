import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('DuplicateDetector', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    const config = MergeConfig();
    const detector = DuplicateDetector(config: config);

    HeartRateSample makeHR({
      required String id,
      required DataProvider provider,
      required DateTime start,
      required DateTime end,
      int bpm = 72,
    }) =>
        HeartRateSample(
          id: id,
          provider: provider,
          providerRecordType: 'heartRate',
          startTime: start,
          endTime: end,
          capturedAt: now,
          beatsPerMinute: bpm,
        );

    test('two HR samples overlapping are detected as overlap', () {
      final a = makeHR(
        id: '1',
        provider: DataProvider.apple,
        start: now,
        end: now.add(const Duration(minutes: 5)),
      );
      final b = makeHR(
        id: '2',
        provider: DataProvider.oura,
        start: now.add(const Duration(minutes: 2)),
        end: now.add(const Duration(minutes: 7)),
      );

      final groups = detector.detectOverlaps([a, b]);
      expect(groups, hasLength(1));
      expect(groups.first, hasLength(2));
    });

    test('two HR samples non-overlapping produce no overlap', () {
      final a = makeHR(
        id: '1',
        provider: DataProvider.apple,
        start: now,
        end: now.add(const Duration(minutes: 1)),
      );
      final b = makeHR(
        id: '2',
        provider: DataProvider.oura,
        start: now.add(const Duration(minutes: 10)),
        end: now.add(const Duration(minutes: 11)),
      );

      final groups = detector.detectOverlaps([a, b]);
      // Each record in its own group of size 1 — no overlaps
      expect(groups.where((g) => g.length > 1), isEmpty);
    });

    test('three records, two overlap, one does not', () {
      final a = makeHR(
        id: '1',
        provider: DataProvider.apple,
        start: now,
        end: now.add(const Duration(minutes: 5)),
      );
      final b = makeHR(
        id: '2',
        provider: DataProvider.oura,
        start: now.add(const Duration(minutes: 3)),
        end: now.add(const Duration(minutes: 8)),
      );
      final c = makeHR(
        id: '3',
        provider: DataProvider.garmin,
        start: now.add(const Duration(minutes: 20)),
        end: now.add(const Duration(minutes: 21)),
      );

      final groups = detector.detectOverlaps([a, b, c]);
      final overlapping = groups.where((g) => g.length > 1).toList();
      final singles = groups.where((g) => g.length == 1).toList();

      expect(overlapping, hasLength(1));
      expect(overlapping.first, hasLength(2));
      expect(singles, hasLength(1));
    });

    test('same provider same time is detected as duplicate', () {
      final a = makeHR(
        id: '1',
        provider: DataProvider.apple,
        start: now,
        end: now.add(const Duration(minutes: 1)),
      );
      final b = makeHR(
        id: '2',
        provider: DataProvider.apple,
        start: now,
        end: now.add(const Duration(minutes: 1)),
      );

      final groups = detector.detectOverlaps([a, b]);
      expect(groups.where((g) => g.length > 1), hasLength(1));
    });

    test('different providers overlapping are detected as conflict', () {
      final a = makeHR(
        id: '1',
        provider: DataProvider.apple,
        start: now,
        end: now.add(const Duration(minutes: 5)),
      );
      final b = makeHR(
        id: '2',
        provider: DataProvider.oura,
        start: now.add(const Duration(minutes: 1)),
        end: now.add(const Duration(minutes: 6)),
      );

      final groups = detector.detectOverlaps([a, b]);
      final overlapGroup = groups.where((g) => g.length > 1).first;
      final providers = overlapGroup.map((r) => r.provider).toSet();
      expect(providers, hasLength(2));
    });

    test('hasTimeOverlap returns true for overlapping records', () {
      final a = makeHR(
        id: '1',
        provider: DataProvider.apple,
        start: now,
        end: now.add(const Duration(minutes: 5)),
      );
      final b = makeHR(
        id: '2',
        provider: DataProvider.oura,
        start: now.add(const Duration(minutes: 3)),
        end: now.add(const Duration(minutes: 8)),
      );

      expect(detector.hasTimeOverlap(a, b), isTrue);
    });

    test('hasTimeOverlap returns false for non-overlapping records', () {
      final a = makeHR(
        id: '1',
        provider: DataProvider.apple,
        start: now,
        end: now.add(const Duration(minutes: 1)),
      );
      final b = makeHR(
        id: '2',
        provider: DataProvider.oura,
        start: now.add(const Duration(minutes: 10)),
        end: now.add(const Duration(minutes: 11)),
      );

      expect(detector.hasTimeOverlap(a, b), isFalse);
    });

    test('records within threshold gap are considered overlapping', () {
      final a = makeHR(
        id: '1',
        provider: DataProvider.apple,
        start: now,
        end: now.add(const Duration(minutes: 1)),
      );
      // Gap of 4 minutes (240 seconds), within 300s threshold
      final b = makeHR(
        id: '2',
        provider: DataProvider.oura,
        start: now.add(const Duration(minutes: 5)),
        end: now.add(const Duration(minutes: 6)),
      );

      expect(detector.hasTimeOverlap(a, b), isTrue);
    });
  });
}

import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('WorkoutRoute', () {
    final now = DateTime.utc(2026, 3, 17, 10);
    final later = DateTime.utc(2026, 3, 17, 11);

    final samplePoints = [
      const RoutePoint(latitude: 37.7749, longitude: -122.4194),
      const RoutePoint(latitude: 37.7750, longitude: -122.4180),
    ];

    WorkoutRoute createMinimal() => WorkoutRoute(
      id: 'wr-1',
      provider: DataProvider.strava,
      providerRecordType: 'route',
      startTime: now,
      endTime: later,
      capturedAt: now,
      points: samplePoints,
    );

    WorkoutRoute createFull() => WorkoutRoute(
      id: 'wr-2',
      provider: DataProvider.garmin,
      providerRecordType: 'courseRoute',
      startTime: now,
      endTime: later,
      timezone: 'US/Pacific',
      capturedAt: now,
      provenance: const Provenance(dataOrigin: DataOrigin.native_),
      freshness: Freshness.cached,
      extensions: const {'format': 'gpx'},
      points: samplePoints,
      totalDistanceMeters: 5000,
      elevationGainMeters: 120,
    );

    test('constructs with required fields only', () {
      final record = createMinimal();
      expect(record.points, hasLength(2));
      expect(record.totalDistanceMeters, isNull);
      expect(record.elevationGainMeters, isNull);
    });

    test('constructs with all fields including optionals', () {
      final record = createFull();
      expect(record.points, hasLength(2));
      expect(record.totalDistanceMeters, 5000.0);
      expect(record.elevationGainMeters, 120.0);
    });

    test('two identical instances are equal', () {
      expect(createMinimal(), equals(createMinimal()));
    });

    test('copyWith works correctly', () {
      final copy = createMinimal().copyWith(totalDistanceMeters: 3000);
      expect(copy.totalDistanceMeters, 3000.0);
      expect(copy.points, hasLength(2));
    });

    test('JSON round-trip produces equal object', () {
      final record = createFull();
      final json = record.toJson();
      final restored = WorkoutRoute.fromJson(json);
      expect(restored, equals(record));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(WorkoutRoute.fromJson(decoded), equals(record));
    });

    test('envelope fields accessible via mixin', () {
      final record = createFull();
      expect(record.id, isNotEmpty);
      expect(record.provider, DataProvider.garmin);
      expect(record.duration, const Duration(hours: 1));
    });

    test('default values are correct', () {
      final record = createMinimal();
      expect(record.freshness, Freshness.live);
      expect(record.extensions, isEmpty);
      expect(record.provenance, isNull);
    });
  });

  group('RoutePoint', () {
    test('constructs with required fields', () {
      const point = RoutePoint(latitude: 37.7749, longitude: -122.4194);
      expect(point.latitude, 37.7749);
      expect(point.longitude, -122.4194);
      expect(point.altitudeMeters, isNull);
      expect(point.timestamp, isNull);
    });

    test('constructs with all fields', () {
      final ts = DateTime.utc(2026, 3, 17, 10, 30);
      final point = RoutePoint(
        latitude: 37.7749,
        longitude: -122.4194,
        altitudeMeters: 50,
        timestamp: ts,
      );
      expect(point.altitudeMeters, 50.0);
      expect(point.timestamp, ts);
    });

    test('equality works', () {
      const a = RoutePoint(latitude: 37.7749, longitude: -122.4194);
      const b = RoutePoint(latitude: 37.7749, longitude: -122.4194);
      expect(a, equals(b));
    });

    test('JSON round-trip', () {
      const point = RoutePoint(latitude: 37.7749, longitude: -122.4194);
      final json = point.toJson();
      final restored = RoutePoint.fromJson(json);
      expect(restored, equals(point));
    });
  });
}

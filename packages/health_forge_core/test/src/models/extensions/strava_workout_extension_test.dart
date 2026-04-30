import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('StravaWorkoutExtension', () {
    test('constructs with all fields', () {
      final ext = StravaWorkoutExtension(
        sufferScore: 120,
        segmentEfforts: [
          {'name': 'Climb A', 'elapsed_time': 300},
        ],
        routePolyline: 'abc123polyline',
      );

      expect(ext.sufferScore, 120);
      expect(ext.segmentEfforts, hasLength(1));
      expect(ext.routePolyline, 'abc123polyline');
    });

    test('constructs with null optional fields', () {
      final ext = StravaWorkoutExtension();

      expect(ext.sufferScore, isNull);
      expect(ext.segmentEfforts, isNull);
      expect(ext.routePolyline, isNull);
    });

    test('typeKey equals strava_workout', () {
      final ext = StravaWorkoutExtension();

      expect(ext.typeKey, 'strava_workout');
    });

    test('JSON round-trip via fromJson/toJson', () {
      final original = StravaWorkoutExtension(
        sufferScore: 120,
        segmentEfforts: [
          {'name': 'Climb A', 'elapsed_time': 300},
        ],
        routePolyline: 'abc123polyline',
      );

      final json = original.toJson();
      final restored = StravaWorkoutExtension.fromJson(json);

      expect(restored.sufferScore, original.sufferScore);
      expect(restored.segmentEfforts, original.segmentEfforts);
      expect(restored.routePolyline, original.routePolyline);
    });

    test('toJson produces correct map', () {
      final ext = StravaWorkoutExtension(
        sufferScore: 120,
        segmentEfforts: [
          {'name': 'Climb A', 'elapsed_time': 300},
        ],
        routePolyline: 'abc123polyline',
      );

      expect(ext.toJson(), {
        'sufferScore': 120,
        'segmentEfforts': [
          {'name': 'Climb A', 'elapsed_time': 300},
        ],
        'routePolyline': 'abc123polyline',
      });
    });

    test('is a ProviderExtension', () {
      final ext = StravaWorkoutExtension();

      expect(ext, isA<ProviderExtension>());
    });
  });
}

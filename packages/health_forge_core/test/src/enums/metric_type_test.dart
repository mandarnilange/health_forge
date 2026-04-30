import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('MetricType', () {
    test('has all expected values', () {
      expect(MetricType.values, hasLength(19));
      expect(
        MetricType.values,
        containsAll([
          MetricType.heartRate,
          MetricType.steps,
          MetricType.sleepSession,
          MetricType.hrv,
          MetricType.restingHeartRate,
          MetricType.bloodOxygen,
          MetricType.respiratoryRate,
          MetricType.weight,
          MetricType.bodyFat,
          MetricType.bloodPressure,
          MetricType.bloodGlucose,
          MetricType.calories,
          MetricType.distance,
          MetricType.elevation,
          MetricType.workout,
          MetricType.readiness,
          MetricType.stress,
          MetricType.recovery,
          MetricType.sleepScore,
        ]),
      );
    });

    test('toString includes value name', () {
      expect(MetricType.heartRate.toString(), contains('heartRate'));
      expect(MetricType.steps.toString(), contains('steps'));
      expect(MetricType.sleepSession.toString(), contains('sleepSession'));
    });

    test('byName round-trip', () {
      for (final value in MetricType.values) {
        expect(MetricType.values.byName(value.name), equals(value));
      }
    });
  });
}

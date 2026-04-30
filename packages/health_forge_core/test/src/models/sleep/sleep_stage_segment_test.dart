import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('SleepStageSegment', () {
    final start = DateTime.utc(2026, 3, 17, 1);
    final end = DateTime.utc(2026, 3, 17, 1, 30);

    test('creates with required fields', () {
      final segment = SleepStageSegment(
        stage: SleepStage.deep,
        startTime: start,
        endTime: end,
      );

      expect(segment.stage, SleepStage.deep);
      expect(segment.startTime, start);
      expect(segment.endTime, end);
    });

    test('supports equality', () {
      final a = SleepStageSegment(
        stage: SleepStage.rem,
        startTime: start,
        endTime: end,
      );
      final b = SleepStageSegment(
        stage: SleepStage.rem,
        startTime: start,
        endTime: end,
      );
      final c = SleepStageSegment(
        stage: SleepStage.light,
        startTime: start,
        endTime: end,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('supports copyWith', () {
      final original = SleepStageSegment(
        stage: SleepStage.awake,
        startTime: start,
        endTime: end,
      );
      final copy = original.copyWith(stage: SleepStage.deep);

      expect(copy.stage, SleepStage.deep);
      expect(copy.startTime, start);
      expect(copy.endTime, end);
    });

    test('serializes to JSON and back', () {
      final segment = SleepStageSegment(
        stage: SleepStage.rem,
        startTime: start,
        endTime: end,
      );

      final json = segment.toJson();
      final restored = SleepStageSegment.fromJson(json);
      expect(restored, equals(segment));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored2 = SleepStageSegment.fromJson(decoded);
      expect(restored2, equals(segment));
    });

    test('supports all stage values', () {
      for (final stage in SleepStage.values) {
        final segment = SleepStageSegment(
          stage: stage,
          startTime: start,
          endTime: end,
        );
        expect(segment.stage, stage);
      }
    });
  });
}

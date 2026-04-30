import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('TimeRange', () {
    final start = DateTime.utc(2026, 3, 17, 10);
    final end = DateTime.utc(2026, 3, 17, 11);

    test('creates with all fields', () {
      final range = TimeRange(
        start: start,
        end: end,
        timezone: 'America/New_York',
      );

      expect(range.start, start);
      expect(range.end, end);
      expect(range.timezone, 'America/New_York');
    });

    test('creates with minimal fields', () {
      final range = TimeRange(start: start, end: end);

      expect(range.start, start);
      expect(range.end, end);
      expect(range.timezone, isNull);
    });

    test('supports equality', () {
      final a = TimeRange(start: start, end: end);
      final b = TimeRange(start: start, end: end);
      final c = TimeRange(
        start: start,
        end: end,
        timezone: 'UTC',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('supports copyWith', () {
      final original = TimeRange(start: start, end: end);
      final copy = original.copyWith(timezone: 'UTC');

      expect(copy.start, start);
      expect(copy.end, end);
      expect(copy.timezone, 'UTC');
    });

    test('serializes to JSON and back', () {
      final range = TimeRange(
        start: start,
        end: end,
        timezone: 'America/New_York',
      );

      final json = range.toJson();
      final restored = TimeRange.fromJson(json);
      expect(restored, equals(range));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored2 = TimeRange.fromJson(decoded);
      expect(restored2, equals(range));
    });
  });
}

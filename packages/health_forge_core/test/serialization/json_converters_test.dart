import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('DateTimeConverter', () {
    const converter = DateTimeConverter();

    test('converts DateTime to ISO 8601 string', () {
      final dt = DateTime.utc(2026, 3, 17, 10, 30);
      final json = converter.toJson(dt);
      expect(json, '2026-03-17T10:30:00.000Z');
    });

    test('converts ISO 8601 string to DateTime', () {
      const json = '2026-03-17T10:30:00.000Z';
      final dt = converter.fromJson(json);
      expect(dt, DateTime.utc(2026, 3, 17, 10, 30));
    });

    test('round-trips correctly', () {
      final original = DateTime.utc(2026, 1, 15, 8, 45, 30, 123);
      final restored = converter.fromJson(converter.toJson(original));
      expect(restored, equals(original));
    });
  });

  group('DurationConverter', () {
    const converter = DurationConverter();

    test('converts Duration to microseconds int', () {
      const duration = Duration(hours: 1, minutes: 30);
      final json = converter.toJson(duration);
      expect(json, duration.inMicroseconds);
    });

    test('converts microseconds int to Duration', () {
      const expected = Duration(hours: 2);
      final duration = converter.fromJson(expected.inMicroseconds);
      expect(duration, expected);
    });

    test('round-trips correctly', () {
      const original = Duration(hours: 8, minutes: 15, seconds: 30);
      final restored = converter.fromJson(converter.toJson(original));
      expect(restored, equals(original));
    });
  });
}

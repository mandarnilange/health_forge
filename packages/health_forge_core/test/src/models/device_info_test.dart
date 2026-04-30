import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('DeviceInfo', () {
    test('creates with all fields', () {
      const info = DeviceInfo(
        model: 'Apple Watch Series 9',
        manufacturer: 'Apple',
        firmware: '10.3',
      );

      expect(info.model, 'Apple Watch Series 9');
      expect(info.manufacturer, 'Apple');
      expect(info.firmware, '10.3');
    });

    test('creates with minimal fields', () {
      const info = DeviceInfo();

      expect(info.model, isNull);
      expect(info.manufacturer, isNull);
      expect(info.firmware, isNull);
    });

    test('supports equality', () {
      const a = DeviceInfo(model: 'Watch', manufacturer: 'Apple');
      const b = DeviceInfo(model: 'Watch', manufacturer: 'Apple');
      const c = DeviceInfo(model: 'Band', manufacturer: 'Garmin');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('supports copyWith', () {
      const original = DeviceInfo(model: 'Watch');
      final copy = original.copyWith(manufacturer: 'Apple');

      expect(copy.model, 'Watch');
      expect(copy.manufacturer, 'Apple');
    });

    test('JSON round-trip via fromJson/toJson', () {
      const info = DeviceInfo(
        model: 'Apple Watch',
        manufacturer: 'Apple',
        firmware: '10.0',
      );

      final json = info.toJson();
      final restored = DeviceInfo.fromJson(json);
      expect(restored, equals(info));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored2 = DeviceInfo.fromJson(decoded);
      expect(restored2, equals(info));
    });
  });
}

import 'dart:convert';

import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('Provenance', () {
    test('creates with all fields', () {
      const provenance = Provenance(
        dataOrigin: DataOrigin.native_,
        sourceDevice: DeviceInfo(
          model: 'Apple Watch',
          manufacturer: 'Apple',
          firmware: '10.0',
        ),
        sourceApp: 'Health',
        rawPayloadRef: 'ref-123',
      );

      expect(provenance.sourceDevice?.model, 'Apple Watch');
      expect(provenance.sourceApp, 'Health');
      expect(provenance.dataOrigin, DataOrigin.native_);
      expect(provenance.rawPayloadRef, 'ref-123');
    });

    test('creates with minimal fields', () {
      const provenance = Provenance(
        dataOrigin: DataOrigin.mapped,
      );

      expect(provenance.sourceDevice, isNull);
      expect(provenance.sourceApp, isNull);
      expect(provenance.dataOrigin, DataOrigin.mapped);
      expect(provenance.rawPayloadRef, isNull);
    });

    test('supports equality', () {
      const a = Provenance(dataOrigin: DataOrigin.native_);
      const b = Provenance(dataOrigin: DataOrigin.native_);
      const c = Provenance(dataOrigin: DataOrigin.mapped);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('supports copyWith', () {
      const original = Provenance(dataOrigin: DataOrigin.native_);
      final copy = original.copyWith(sourceApp: 'Oura');

      expect(copy.sourceApp, 'Oura');
      expect(copy.dataOrigin, DataOrigin.native_);
    });

    test('serializes to JSON and back', () {
      const provenance = Provenance(
        dataOrigin: DataOrigin.native_,
        sourceDevice: DeviceInfo(
          model: 'Apple Watch',
          manufacturer: 'Apple',
          firmware: '10.0',
        ),
        sourceApp: 'Health',
        rawPayloadRef: 'ref-123',
      );

      final json = provenance.toJson();
      final restored = Provenance.fromJson(json);
      expect(restored, equals(provenance));

      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final restored2 = Provenance.fromJson(decoded);
      expect(restored2, equals(provenance));
    });
  });
}

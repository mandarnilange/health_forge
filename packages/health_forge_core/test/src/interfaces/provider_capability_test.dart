import 'package:health_forge_core/src/enums/access_mode.dart';
import 'package:health_forge_core/src/enums/data_origin.dart';
import 'package:health_forge_core/src/enums/metric_type.dart';
import 'package:health_forge_core/src/enums/sync_model.dart';
import 'package:health_forge_core/src/interfaces/provider_capability.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderCapabilities', () {
    late ProviderCapabilities capabilities;

    setUp(() {
      capabilities = const ProviderCapabilities(
        supportedMetrics: {
          MetricType.heartRate: AccessMode.read,
          MetricType.steps: AccessMode.readWrite,
        },
        syncModel: SyncModel.incrementalCursor,
      );
    });

    group('supports', () {
      test('returns true for supported metric', () {
        expect(capabilities.supports(MetricType.heartRate), isTrue);
      });

      test('returns true for another supported metric', () {
        expect(capabilities.supports(MetricType.steps), isTrue);
      });

      test('returns false for unsupported metric', () {
        expect(capabilities.supports(MetricType.sleepSession), isFalse);
      });
    });

    group('accessMode', () {
      test('returns correct mode for supported metric', () {
        expect(
          capabilities.accessMode(MetricType.heartRate),
          AccessMode.read,
        );
      });

      test('returns readWrite for metric with that mode', () {
        expect(
          capabilities.accessMode(MetricType.steps),
          AccessMode.readWrite,
        );
      });

      test('returns null for unsupported metric', () {
        expect(capabilities.accessMode(MetricType.weight), isNull);
      });
    });

    group('dataOriginFor', () {
      test('returns native by default', () {
        expect(
          capabilities.dataOriginFor(MetricType.heartRate),
          DataOrigin.native_,
        );
      });
    });

    test('exposes syncModel', () {
      expect(capabilities.syncModel, SyncModel.incrementalCursor);
    });
  });
}

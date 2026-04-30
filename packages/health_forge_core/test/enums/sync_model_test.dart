import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('SyncModel', () {
    test('has all expected values', () {
      expect(SyncModel.values, hasLength(3));
      expect(
        SyncModel.values,
        containsAll([
          SyncModel.fullWindow,
          SyncModel.incrementalCursor,
          SyncModel.polling,
        ]),
      );
    });

    test('JSON round-trip', () {
      for (final value in SyncModel.values) {
        expect(SyncModel.values.byName(value.name), equals(value));
      }
    });
  });
}

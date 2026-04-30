import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('ConflictStrategyHandler', () {
    test('KeepAllWithAttributionStrategy implements ConflictStrategyHandler',
        () {
      final handler = KeepAllWithAttributionStrategy();

      expect(handler, isA<ConflictStrategyHandler>());
    });

    test('PriorityBasedStrategy implements ConflictStrategyHandler', () {
      final handler = PriorityBasedStrategy();

      expect(handler, isA<ConflictStrategyHandler>());
    });

    test('AverageStrategy implements ConflictStrategyHandler', () {
      final handler = AverageStrategy();

      expect(handler, isA<ConflictStrategyHandler>());
    });

    test('MostGranularStrategy implements ConflictStrategyHandler', () {
      final handler = MostGranularStrategy();

      expect(handler, isA<ConflictStrategyHandler>());
    });

    test('CustomStrategy implements ConflictStrategyHandler', () {
      final handler = CustomStrategy(
        resolver: (conflicts, metricType) => conflicts,
      );

      expect(handler, isA<ConflictStrategyHandler>());
    });
  });
}

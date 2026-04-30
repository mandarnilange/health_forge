import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('IdGenerator', () {
    test('generates a non-empty string', () {
      final id = IdGenerator.generate();
      expect(id, isNotEmpty);
    });

    test('generates unique IDs', () {
      final ids = List.generate(100, (_) => IdGenerator.generate());
      expect(ids.toSet().length, 100);
    });

    test('generates valid UUID v4 format', () {
      final id = IdGenerator.generate();
      expect(
        id,
        matches(
          RegExp(
            '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
            r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });
  });
}

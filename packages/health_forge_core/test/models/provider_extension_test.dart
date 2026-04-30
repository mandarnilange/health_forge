import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

class TestProviderExtension extends ProviderExtension {
  TestProviderExtension({required this.customField});

  final String customField;

  @override
  Map<String, dynamic> toJson() => {'customField': customField};
}

void main() {
  group('ProviderExtension', () {
    test('can be extended and serialized', () {
      final ext = TestProviderExtension(customField: 'hello');
      final json = ext.toJson();

      expect(json, {'customField': 'hello'});
    });
  });
}

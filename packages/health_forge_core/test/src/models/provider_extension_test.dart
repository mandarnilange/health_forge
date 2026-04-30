import 'package:health_forge_core/health_forge_core.dart';
import 'package:test/test.dart';

class _TestProviderExtension extends ProviderExtension {
  _TestProviderExtension({required this.customField});

  final String customField;

  @override
  Map<String, dynamic> toJson() => {'customField': customField};
}

void main() {
  group('ProviderExtension', () {
    test('can be extended and serialized via toJson', () {
      final ext = _TestProviderExtension(customField: 'hello');
      final json = ext.toJson();

      expect(json, {'customField': 'hello'});
    });

    test('subclass is a ProviderExtension', () {
      final ext = _TestProviderExtension(customField: 'world');

      expect(ext, isA<ProviderExtension>());
    });
  });
}

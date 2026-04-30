import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_oura/src/mappers/spo2_mapper.dart';
import 'package:health_forge_oura/src/models/oura_daily_spo2_response.dart';

void main() {
  group('Spo2Mapper', () {
    late OuraDailySpo2Response response;

    setUp(() {
      response = const OuraDailySpo2Response(
        data: [
          OuraDailySpo2Data(
            id: 'spo2_001',
            day: '2024-01-15',
            spo2Percentage: OuraSpo2Percentage(average: 97.5),
          ),
        ],
      );
    });

    test('maps blood oxygen sample', () {
      final samples = Spo2Mapper.map(response);
      expect(samples, hasLength(1));

      final sample = samples.first;
      expect(sample.provider, DataProvider.oura);
      expect(sample.providerRecordType, 'daily_spo2');
      expect(sample.percentage, 97.5);
    });

    test('skips entries with null spo2_percentage', () {
      response = const OuraDailySpo2Response(
        data: [
          OuraDailySpo2Data(
            id: 'spo2_002',
            day: '2024-01-15',
          ),
        ],
      );
      final samples = Spo2Mapper.map(response);
      expect(samples, isEmpty);
    });

    test('skips entries with null average', () {
      response = const OuraDailySpo2Response(
        data: [
          OuraDailySpo2Data(
            id: 'spo2_003',
            day: '2024-01-15',
            spo2Percentage: OuraSpo2Percentage(),
          ),
        ],
      );
      final samples = Spo2Mapper.map(response);
      expect(samples, isEmpty);
    });

    test('handles empty response', () {
      final samples = Spo2Mapper.map(
        const OuraDailySpo2Response(data: []),
      );
      expect(samples, isEmpty);
    });
  });
}

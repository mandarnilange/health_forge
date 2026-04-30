import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge/health_forge.dart';
import 'package:mocktail/mocktail.dart';

class MockHealthRecord extends Mock implements HealthRecordMixin {}

void main() {
  group('QueryResult', () {
    final mockRecord = MockHealthRecord();

    test('construction with all fields', () {
      final mergeResult = MergeResult(
        resolved: [mockRecord],
        conflicts: [],
        rawSources: [mockRecord],
      );

      final result = QueryResult(
        records: [mockRecord],
        mergeResult: mergeResult,
        errors: {DataProvider.apple: 'timeout'},
        fetchDuration: const Duration(seconds: 2),
      );

      expect(result.records, hasLength(1));
      expect(result.records.first, mockRecord);
      expect(result.mergeResult, mergeResult);
      expect(result.errors, {DataProvider.apple: 'timeout'});
      expect(result.fetchDuration, const Duration(seconds: 2));
    });

    test('construction without mergeResult defaults to null', () {
      const result = QueryResult(
        records: [],
        errors: {},
        fetchDuration: Duration.zero,
      );

      expect(result.mergeResult, isNull);
    });

    test('records field returns provided list', () {
      final records = [MockHealthRecord(), MockHealthRecord()];

      final result = QueryResult(
        records: records,
        errors: {},
        fetchDuration: const Duration(milliseconds: 500),
      );

      expect(result.records, hasLength(2));
      expect(result.records, equals(records));
    });

    test('errors field stores provider-keyed error messages', () {
      final errors = {
        DataProvider.apple: 'unauthorized',
        DataProvider.oura: 'rate limited',
      };

      final result = QueryResult(
        records: [],
        errors: errors,
        fetchDuration: const Duration(seconds: 1),
      );

      expect(result.errors, hasLength(2));
      expect(result.errors[DataProvider.apple], 'unauthorized');
      expect(result.errors[DataProvider.oura], 'rate limited');
    });

    test('fetchDuration stores elapsed time', () {
      const result = QueryResult(
        records: [],
        errors: {},
        fetchDuration: Duration(milliseconds: 1234),
      );

      expect(result.fetchDuration.inMilliseconds, 1234);
    });

    test('empty result has no records, no errors, and zero duration', () {
      const result = QueryResult(
        records: [],
        errors: {},
        fetchDuration: Duration.zero,
      );

      expect(result.records, isEmpty);
      expect(result.mergeResult, isNull);
      expect(result.errors, isEmpty);
      expect(result.fetchDuration, Duration.zero);
    });
  });
}

import 'package:health_forge_core/health_forge_core.dart';

/// The result of executing a health data query.
class QueryResult {
  /// Creates a [QueryResult].
  const QueryResult({
    required this.records,
    required this.errors,
    required this.fetchDuration,
    this.mergeResult,
  });

  /// The resolved health records returned by the query.
  final List<HealthRecordMixin> records;

  /// The merge result, if merging was applied.
  final MergeResult? mergeResult;

  /// Errors encountered per provider during fetching.
  final Map<DataProvider, String> errors;

  /// Total time spent fetching data from providers.
  final Duration fetchDuration;
}

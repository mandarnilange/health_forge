import 'package:health_forge_core/src/enums/conflict_strategy.dart';
import 'package:health_forge_core/src/enums/metric_type.dart';
import 'package:health_forge_core/src/models/health_record.dart';

/// The output of a merge operation, containing resolved records and
/// information about any conflicts that were detected and resolved.
class MergeResult {
  /// Creates a [MergeResult].
  const MergeResult({
    required this.resolved,
    required this.conflicts,
    required this.rawSources,
  });

  /// The deduplicated, conflict-resolved records.
  final List<HealthRecordMixin> resolved;

  /// Reports for each conflict group that was resolved.
  final List<ConflictReport> conflicts;

  /// The original unmodified input records.
  final List<HealthRecordMixin> rawSources;
}

/// Describes a single conflict group and how it was resolved.
class ConflictReport {
  /// Creates a [ConflictReport].
  const ConflictReport({
    required this.metricType,
    required this.strategy,
    required this.inputRecords,
    required this.resolvedRecord,
    required this.reason,
  });

  /// The metric type of the conflicting records.
  final MetricType metricType;

  /// The strategy used to resolve this conflict.
  final ConflictStrategy strategy;

  /// The overlapping records that formed this conflict group.
  final List<HealthRecordMixin> inputRecords;

  /// When the strategy returns a single winner, that record. When it
  /// returns multiple outputs (e.g. [ConflictStrategy.keepAll]), this is
  /// the **first** resolved record only — see [MergeResult.resolved] for the
  /// full merged list. Null if the strategy produced no records.
  final HealthRecordMixin? resolvedRecord;

  /// Human-readable explanation of the resolution.
  final String reason;
}

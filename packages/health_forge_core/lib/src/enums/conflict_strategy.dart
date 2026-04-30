import 'package:json_annotation/json_annotation.dart';

/// Strategy used to resolve conflicts when duplicate records are detected.
@JsonEnum()
enum ConflictStrategy {
  /// Selects the record from the highest-priority provider.
  priorityBased,

  /// Keeps all conflicting records with source attribution.
  keepAll,

  /// Averages numeric values across conflicting records.
  average,

  /// Selects the record with the shortest duration (most granular).
  mostGranular,

  /// Delegates resolution to a user-supplied callback.
  custom,
}

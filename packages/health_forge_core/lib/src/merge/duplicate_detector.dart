import 'package:health_forge_core/src/merge/merge_config.dart';
import 'package:health_forge_core/src/models/health_record.dart';

/// Detects overlapping health records that likely represent duplicates.
///
/// Uses the time-overlap threshold from [MergeConfig] to group records
/// whose measurement intervals overlap.
class DuplicateDetector {
  /// Creates a [DuplicateDetector] with the given [config].
  const DuplicateDetector({required this.config});

  /// The merge configuration providing the overlap threshold.
  final MergeConfig config;

  /// Groups records into overlap clusters.
  ///
  /// Records that overlap in time (within the configured threshold) are
  /// grouped together. Non-overlapping records appear as single-element lists.
  List<List<HealthRecordMixin>> detectOverlaps(
    List<HealthRecordMixin> records,
  ) {
    if (records.isEmpty) return [];

    final sorted = List<HealthRecordMixin>.from(records)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final groups = <List<HealthRecordMixin>>[];
    var currentGroup = <HealthRecordMixin>[sorted.first];

    for (var i = 1; i < sorted.length; i++) {
      final record = sorted[i];
      final overlapsWithGroup =
          currentGroup.any((r) => hasTimeOverlap(r, record));

      if (overlapsWithGroup) {
        currentGroup.add(record);
      } else {
        groups.add(currentGroup);
        currentGroup = [record];
      }
    }
    groups.add(currentGroup);

    return groups;
  }

  /// Check if two records overlap in time, considering the threshold.
  bool hasTimeOverlap(HealthRecordMixin a, HealthRecordMixin b) {
    final threshold = Duration(seconds: config.timeOverlapThresholdSeconds);
    final aEnd = a.endTime.add(threshold);
    final bEnd = b.endTime.add(threshold);

    return a.startTime.isBefore(bEnd) && b.startTime.isBefore(aEnd);
  }
}

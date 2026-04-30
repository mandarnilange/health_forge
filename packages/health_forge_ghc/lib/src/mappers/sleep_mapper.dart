import 'package:health_forge_core/health_forge_core.dart';
import 'package:health_forge_ghc/src/health_data_record.dart';

/// Maps Health Connect sleep data points to core [SleepSession] records.
class SleepMapper {
  const SleepMapper._();

  static const _stageMap = <String, SleepStage>{
    'SLEEP_ASLEEP': SleepStage.unknown,
    'SLEEP_AWAKE': SleepStage.awake,
    'SLEEP_DEEP': SleepStage.deep,
    'SLEEP_LIGHT': SleepStage.light,
    'SLEEP_REM': SleepStage.rem,
  };

  /// Meta types that define the session envelope but are not stage segments.
  static const _metaTypes = {'SLEEP_ASLEEP'};

  /// Converts a single [HealthDataRecord] to a [SleepSession].
  static HealthRecordMixin map(HealthDataRecord record) {
    if (!_stageMap.containsKey(record.type)) {
      throw ArgumentError('Unsupported type: ${record.type}');
    }

    final id = record.uuid.isEmpty ? IdGenerator.generate() : record.uuid;

    return SleepSession(
      id: id,
      provider: DataProvider.googleHealthConnect,
      providerRecordType: record.type,
      providerRecordId: record.uuid.isNotEmpty ? record.uuid : null,
      startTime: record.dateFrom,
      endTime: record.dateTo,
      capturedAt: DateTime.now(),
      provenance: Provenance(
        dataOrigin: DataOrigin.native_,
        sourceDevice: DeviceInfo(
          model: record.deviceModel,
          manufacturer: record.sourceName,
        ),
        sourceApp: record.sourceId,
      ),
    );
  }

  /// Aggregates multiple sleep data points into [SleepSession]s grouped by
  /// source. Within each source, records are deduplicated by
  /// (type, dateFrom, dateTo) to prevent double-counting from synced devices.
  /// Stage segments are sorted chronologically and duration minutes
  /// are calculated from actual time ranges.
  static List<SleepSession> mapAll(List<HealthDataRecord> records) {
    if (records.isEmpty) return const [];

    // Group records by source (sourceName + sourceId).
    final groups = <String, List<HealthDataRecord>>{};
    for (final record in records) {
      final key = '${record.sourceName}|${record.sourceId}';
      (groups[key] ??= []).add(record);
    }

    return groups.values.map(_buildSession).toList();
  }

  static SleepSession _buildSession(List<HealthDataRecord> records) {
    // Deduplicate records by (type, dateFrom, dateTo) within this source.
    final seen = <String>{};
    final deduped = <HealthDataRecord>[];
    for (final r in records) {
      final key = '${r.type}|${r.dateFrom.millisecondsSinceEpoch}'
          '|${r.dateTo.millisecondsSinceEpoch}';
      if (seen.add(key)) deduped.add(r);
    }

    // Separate stage segments from meta records (ASLEEP).
    final stageRecords =
        deduped.where((r) => !_metaTypes.contains(r.type)).toList();

    // Build stage segments from non-meta records.
    final stages = stageRecords.map((r) {
      return SleepStageSegment(
        stage: _stageMap[r.type]!,
        startTime: r.dateFrom,
        endTime: r.dateTo,
      );
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Session envelope: use all records (including meta) for time range.
    var earliest = deduped.first.dateFrom;
    var latest = deduped.first.dateTo;
    for (final r in deduped) {
      if (r.dateFrom.isBefore(earliest)) earliest = r.dateFrom;
      if (r.dateTo.isAfter(latest)) latest = r.dateTo;
    }

    // Calculate duration minutes per stage from actual time ranges.
    int? deepMin;
    int? lightMin;
    int? remMin;
    int? awakeMin;

    for (final r in stageRecords) {
      final minutes = r.dateTo.difference(r.dateFrom).inMinutes.abs();
      switch (r.type) {
        case 'SLEEP_DEEP':
          deepMin = (deepMin ?? 0) + minutes;
        case 'SLEEP_LIGHT':
          lightMin = (lightMin ?? 0) + minutes;
        case 'SLEEP_REM':
          remMin = (remMin ?? 0) + minutes;
        case 'SLEEP_AWAKE':
          awakeMin = (awakeMin ?? 0) + minutes;
      }
    }

    // Total sleep = deep + light + rem (excludes awake).
    final totalSleep = (deepMin ?? 0) + (lightMin ?? 0) + (remMin ?? 0);

    final first = deduped.first;

    return SleepSession(
      id: IdGenerator.generate(),
      provider: DataProvider.googleHealthConnect,
      providerRecordType: 'SLEEP_SESSION',
      startTime: earliest,
      endTime: latest,
      capturedAt: DateTime.now(),
      totalSleepMinutes: totalSleep > 0 ? totalSleep : null,
      deepMinutes: deepMin,
      lightMinutes: lightMin,
      remMinutes: remMin,
      awakeMinutes: awakeMin,
      stages: stages,
      provenance: Provenance(
        dataOrigin: DataOrigin.native_,
        sourceDevice: DeviceInfo(
          model: first.deviceModel,
          manufacturer: first.sourceName,
        ),
        sourceApp: first.sourceId,
      ),
    );
  }
}

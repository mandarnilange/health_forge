import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';
import 'package:health_forge_core/src/models/sleep/sleep_stage_segment.dart';

part 'sleep_session.freezed.dart';
part 'sleep_session.g.dart';

/// A sleep session with duration breakdowns by stage and efficiency.
@freezed
abstract class SleepSession with _$SleepSession, HealthRecordMixin {
  const SleepSession._();
  const factory SleepSession({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    String? providerRecordId,
    String? timezone,
    Provenance? provenance,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
    int? totalSleepMinutes,
    int? remMinutes,
    int? deepMinutes,
    int? lightMinutes,
    int? awakeMinutes,
    int? efficiency,
    @Default(<SleepStageSegment>[]) List<SleepStageSegment> stages,
  }) = _SleepSession;

  factory SleepSession.fromJson(Map<String, dynamic> json) =>
      _$SleepSessionFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'step_count.freezed.dart';
part 'step_count.g.dart';

/// A step count measurement over a time interval.
@freezed
abstract class StepCount with _$StepCount, HealthRecordMixin {
  const StepCount._();
  const factory StepCount({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required int count,
    String? providerRecordId,
    String? timezone,
    Provenance? provenance,
    String? source,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _StepCount;

  factory StepCount.fromJson(Map<String, dynamic> json) =>
      _$StepCountFromJson(json);
}

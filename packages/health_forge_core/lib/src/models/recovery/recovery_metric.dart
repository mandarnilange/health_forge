import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'recovery_metric.freezed.dart';
part 'recovery_metric.g.dart';

/// A recovery score with an optional qualitative level.
@freezed
abstract class RecoveryMetric with _$RecoveryMetric, HealthRecordMixin {
  const RecoveryMetric._();
  const factory RecoveryMetric({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required int score,
    String? providerRecordId,
    String? recoveryLevel,
    String? timezone,
    Provenance? provenance,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _RecoveryMetric;

  factory RecoveryMetric.fromJson(Map<String, dynamic> json) =>
      _$RecoveryMetricFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'heart_rate_variability.freezed.dart';
part 'heart_rate_variability.g.dart';

/// A heart rate variability measurement (SDNN and optional RMSSD).
@freezed
abstract class HeartRateVariability
    with _$HeartRateVariability, HealthRecordMixin {
  const HeartRateVariability._();
  const factory HeartRateVariability({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required double sdnnMilliseconds,
    String? providerRecordId,
    String? timezone,
    Provenance? provenance,
    double? rmssdMilliseconds,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _HeartRateVariability;

  factory HeartRateVariability.fromJson(Map<String, dynamic> json) =>
      _$HeartRateVariabilityFromJson(json);
}

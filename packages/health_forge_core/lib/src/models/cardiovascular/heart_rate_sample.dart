import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'heart_rate_sample.freezed.dart';
part 'heart_rate_sample.g.dart';

/// A heart rate measurement at a point in time.
@freezed
abstract class HeartRateSample with _$HeartRateSample, HealthRecordMixin {
  const HeartRateSample._();
  const factory HeartRateSample({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required int beatsPerMinute,
    String? providerRecordId,
    String? timezone,
    Provenance? provenance,
    String? context,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _HeartRateSample;

  factory HeartRateSample.fromJson(Map<String, dynamic> json) =>
      _$HeartRateSampleFromJson(json);
}

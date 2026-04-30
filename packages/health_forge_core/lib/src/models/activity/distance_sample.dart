import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'distance_sample.freezed.dart';
part 'distance_sample.g.dart';

/// A distance measurement in meters over a time interval.
@freezed
abstract class DistanceSample with _$DistanceSample, HealthRecordMixin {
  const DistanceSample._();
  const factory DistanceSample({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required double distanceMeters,
    String? providerRecordId,
    String? timezone,
    Provenance? provenance,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _DistanceSample;

  factory DistanceSample.fromJson(Map<String, dynamic> json) =>
      _$DistanceSampleFromJson(json);
}

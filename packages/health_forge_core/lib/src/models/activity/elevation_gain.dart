import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'elevation_gain.freezed.dart';
part 'elevation_gain.g.dart';

/// Cumulative elevation gain in meters over a time interval.
@freezed
abstract class ElevationGain with _$ElevationGain, HealthRecordMixin {
  const ElevationGain._();
  const factory ElevationGain({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required double elevationMeters,
    String? providerRecordId,
    String? timezone,
    Provenance? provenance,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _ElevationGain;

  factory ElevationGain.fromJson(Map<String, dynamic> json) =>
      _$ElevationGainFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'resting_heart_rate.freezed.dart';
part 'resting_heart_rate.g.dart';

/// A resting heart rate measurement in beats per minute.
@freezed
abstract class RestingHeartRate with _$RestingHeartRate, HealthRecordMixin {
  const RestingHeartRate._();
  const factory RestingHeartRate({
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
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _RestingHeartRate;

  factory RestingHeartRate.fromJson(Map<String, dynamic> json) =>
      _$RestingHeartRateFromJson(json);
}

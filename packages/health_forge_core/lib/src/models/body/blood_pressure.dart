import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'blood_pressure.freezed.dart';
part 'blood_pressure.g.dart';

/// A blood pressure reading with systolic and diastolic values in mmHg.
@freezed
abstract class BloodPressure with _$BloodPressure, HealthRecordMixin {
  const BloodPressure._();
  const factory BloodPressure({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required int systolicMmHg,
    required int diastolicMmHg,
    String? providerRecordId,
    int? pulseBpm,
    String? timezone,
    Provenance? provenance,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _BloodPressure;

  factory BloodPressure.fromJson(Map<String, dynamic> json) =>
      _$BloodPressureFromJson(json);
}

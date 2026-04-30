import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'blood_glucose.freezed.dart';
part 'blood_glucose.g.dart';

/// A blood glucose concentration reading in mg/dL.
@freezed
abstract class BloodGlucose with _$BloodGlucose, HealthRecordMixin {
  const BloodGlucose._();
  const factory BloodGlucose({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required double milligramsPerDeciliter,
    String? providerRecordId,
    String? mealContext,
    String? timezone,
    Provenance? provenance,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _BloodGlucose;

  factory BloodGlucose.fromJson(Map<String, dynamic> json) =>
      _$BloodGlucoseFromJson(json);
}

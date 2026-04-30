import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'blood_oxygen_sample.freezed.dart';
part 'blood_oxygen_sample.g.dart';

/// A blood oxygen saturation (SpO2) measurement as a percentage.
@freezed
abstract class BloodOxygenSample with _$BloodOxygenSample, HealthRecordMixin {
  const BloodOxygenSample._();
  const factory BloodOxygenSample({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required double percentage,
    String? providerRecordId,
    bool? supplementalOxygen,
    String? timezone,
    Provenance? provenance,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _BloodOxygenSample;

  factory BloodOxygenSample.fromJson(Map<String, dynamic> json) =>
      _$BloodOxygenSampleFromJson(json);
}

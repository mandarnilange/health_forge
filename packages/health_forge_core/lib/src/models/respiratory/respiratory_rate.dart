import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'respiratory_rate.freezed.dart';
part 'respiratory_rate.g.dart';

/// A respiratory rate measurement in breaths per minute.
@freezed
abstract class RespiratoryRate with _$RespiratoryRate, HealthRecordMixin {
  const RespiratoryRate._();
  const factory RespiratoryRate({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required double breathsPerMinute,
    String? providerRecordId,
    String? timezone,
    Provenance? provenance,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _RespiratoryRate;

  factory RespiratoryRate.fromJson(Map<String, dynamic> json) =>
      _$RespiratoryRateFromJson(json);
}

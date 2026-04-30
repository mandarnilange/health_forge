import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'body_fat.freezed.dart';
part 'body_fat.g.dart';

/// A body fat percentage measurement.
@freezed
abstract class BodyFat with _$BodyFat, HealthRecordMixin {
  const BodyFat._();
  const factory BodyFat({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required double percentage,
    String? providerRecordId,
    String? timezone,
    Provenance? provenance,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _BodyFat;

  factory BodyFat.fromJson(Map<String, dynamic> json) =>
      _$BodyFatFromJson(json);
}

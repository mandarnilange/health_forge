import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'weight.freezed.dart';
part 'weight.g.dart';

/// A body weight measurement in kilograms.
@freezed
abstract class Weight with _$Weight, HealthRecordMixin {
  const Weight._();
  const factory Weight({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required double kilograms,
    String? providerRecordId,
    double? bmi,
    String? timezone,
    Provenance? provenance,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _Weight;

  factory Weight.fromJson(Map<String, dynamic> json) => _$WeightFromJson(json);
}

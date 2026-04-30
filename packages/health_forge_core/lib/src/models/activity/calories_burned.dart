import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'calories_burned.freezed.dart';
part 'calories_burned.g.dart';

/// Calories burned over a time interval.
@freezed
abstract class CaloriesBurned with _$CaloriesBurned, HealthRecordMixin {
  const CaloriesBurned._();
  const factory CaloriesBurned({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required double totalCalories,
    String? providerRecordId,
    String? timezone,
    Provenance? provenance,
    double? activeCalories,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _CaloriesBurned;

  factory CaloriesBurned.fromJson(Map<String, dynamic> json) =>
      _$CaloriesBurnedFromJson(json);
}

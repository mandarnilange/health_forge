import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'stress_score.freezed.dart';
part 'stress_score.g.dart';

/// A stress level score with an optional qualitative level label.
@freezed
abstract class StressScore with _$StressScore, HealthRecordMixin {
  const StressScore._();
  const factory StressScore({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required int score,
    String? providerRecordId,
    String? level,
    String? timezone,
    Provenance? provenance,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _StressScore;

  factory StressScore.fromJson(Map<String, dynamic> json) =>
      _$StressScoreFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'readiness_score.freezed.dart';
part 'readiness_score.g.dart';

/// A readiness-to-perform score with optional contributor breakdowns.
@freezed
abstract class ReadinessScore with _$ReadinessScore, HealthRecordMixin {
  const ReadinessScore._();
  const factory ReadinessScore({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required int score,
    String? providerRecordId,
    Map<String, int>? contributors,
    String? timezone,
    Provenance? provenance,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _ReadinessScore;

  factory ReadinessScore.fromJson(Map<String, dynamic> json) =>
      _$ReadinessScoreFromJson(json);
}

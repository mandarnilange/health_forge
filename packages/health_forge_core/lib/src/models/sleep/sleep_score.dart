import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'sleep_score.freezed.dart';
part 'sleep_score.g.dart';

/// An overall sleep quality score with an optional quality rating.
@freezed
abstract class SleepScore with _$SleepScore, HealthRecordMixin {
  const SleepScore._();
  const factory SleepScore({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required int score,
    String? providerRecordId,
    String? qualityRating,
    String? timezone,
    Provenance? provenance,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _SleepScore;

  factory SleepScore.fromJson(Map<String, dynamic> json) =>
      _$SleepScoreFromJson(json);
}

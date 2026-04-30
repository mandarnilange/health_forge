import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/enums/metric_type.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'activity_session.freezed.dart';
part 'activity_session.g.dart';

/// A workout or activity session (e.g. running, cycling, swimming).
@freezed
abstract class ActivitySession with _$ActivitySession, HealthRecordMixin {
  const ActivitySession._();
  const factory ActivitySession({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required MetricType activityType,
    String? providerRecordId,
    String? timezone,
    Provenance? provenance,
    String? activityName,
    double? totalCalories,
    double? activeCalories,
    double? distanceMeters,
    int? averageHeartRate,
    int? maxHeartRate,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _ActivitySession;

  factory ActivitySession.fromJson(Map<String, dynamic> json) =>
      _$ActivitySessionFromJson(json);
}

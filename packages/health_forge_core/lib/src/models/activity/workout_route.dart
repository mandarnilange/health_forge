import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/health_record.dart';
import 'package:health_forge_core/src/models/provenance.dart';

part 'workout_route.freezed.dart';
part 'workout_route.g.dart';

/// A single GPS point along a workout route.
@freezed
abstract class RoutePoint with _$RoutePoint {
  const factory RoutePoint({
    required double latitude,
    required double longitude,
    double? altitudeMeters,
    DateTime? timestamp,
  }) = _RoutePoint;

  factory RoutePoint.fromJson(Map<String, dynamic> json) =>
      _$RoutePointFromJson(json);
}

/// A GPS route associated with a workout, composed of [RoutePoint]s.
@freezed
abstract class WorkoutRoute with _$WorkoutRoute, HealthRecordMixin {
  const WorkoutRoute._();
  const factory WorkoutRoute({
    required String id,
    required DataProvider provider,
    required String providerRecordType,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime capturedAt,
    required List<RoutePoint> points,
    String? providerRecordId,
    String? timezone,
    Provenance? provenance,
    double? totalDistanceMeters,
    double? elevationGainMeters,
    @Default(Freshness.live) Freshness freshness,
    @Default(<String, dynamic>{}) Map<String, dynamic> extensions,
  }) = _WorkoutRoute;

  factory WorkoutRoute.fromJson(Map<String, dynamic> json) =>
      _$WorkoutRouteFromJson(json);
}

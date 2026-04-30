import 'package:freezed_annotation/freezed_annotation.dart';

part 'sleep_stage_segment.freezed.dart';
part 'sleep_stage_segment.g.dart';

/// The stage of sleep during a segment.
enum SleepStage {
  /// Subject was awake.
  awake,

  /// Light sleep stage.
  light,

  /// Deep (slow-wave) sleep stage.
  deep,

  /// REM sleep stage.
  rem,

  /// Sleep stage could not be determined.
  unknown,
}

/// A contiguous segment of a single sleep stage within a sleep session.
@freezed
abstract class SleepStageSegment with _$SleepStageSegment {
  const factory SleepStageSegment({
    required SleepStage stage,
    required DateTime startTime,
    required DateTime endTime,
  }) = _SleepStageSegment;

  factory SleepStageSegment.fromJson(Map<String, dynamic> json) =>
      _$SleepStageSegmentFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'time_range.freezed.dart';
part 'time_range.g.dart';

/// A half-open time interval used to scope health data queries.
@freezed
abstract class TimeRange with _$TimeRange {
  /// Creates a [TimeRange].
  const factory TimeRange({
    /// Inclusive start of the range.
    required DateTime start,

    /// Exclusive end of the range.
    required DateTime end,

    /// Optional IANA timezone identifier for this range.
    String? timezone,
  }) = _TimeRange;

  factory TimeRange.fromJson(Map<String, dynamic> json) =>
      _$TimeRangeFromJson(json);
}

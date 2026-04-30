import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_info.freezed.dart';
part 'device_info.g.dart';

/// Information about the device that captured a health record.
@freezed
abstract class DeviceInfo with _$DeviceInfo {
  /// Creates a [DeviceInfo].
  const factory DeviceInfo({
    /// Device model name (e.g. "Apple Watch Series 9").
    String? model,

    /// Device manufacturer (e.g. "Apple", "Garmin").
    String? manufacturer,

    /// Firmware or OS version running on the device.
    String? firmware,
  }) = _DeviceInfo;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);
}

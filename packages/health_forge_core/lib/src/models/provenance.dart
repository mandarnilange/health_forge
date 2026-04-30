import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:health_forge_core/src/enums/data_origin.dart';
import 'package:health_forge_core/src/models/device_info.dart';

part 'provenance.freezed.dart';
part 'provenance.g.dart';

/// Tracks how and where a health record was produced.
@freezed
abstract class Provenance with _$Provenance {
  /// Creates a [Provenance].
  const factory Provenance({
    /// How the data was obtained (native, mapped, derived, etc.).
    required DataOrigin dataOrigin,

    /// The device that captured the record, if known.
    DeviceInfo? sourceDevice,

    /// The application that produced the record.
    String? sourceApp,

    /// Reference to the raw payload for audit purposes.
    String? rawPayloadRef,
  }) = _Provenance;

  factory Provenance.fromJson(Map<String, dynamic> json) =>
      _$ProvenanceFromJson(json);
}

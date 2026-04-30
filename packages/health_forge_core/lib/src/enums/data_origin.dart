import 'package:json_annotation/json_annotation.dart';

/// How a health record was obtained from its source provider.
@JsonEnum()
enum DataOrigin {
  /// Directly recorded by the provider's native sensor or API.
  @JsonValue('native')
  native_,

  /// Mapped from a different data format or schema.
  mapped,

  /// Derived through calculation from other records.
  derived,

  /// Estimated using algorithms or heuristics.
  estimated,

  /// Extracted from a raw payload or composite record.
  extracted,
}

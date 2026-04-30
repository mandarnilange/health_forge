import 'package:json_annotation/json_annotation.dart';

/// The access mode a provider supports for a given metric.
@JsonEnum()
enum AccessMode {
  /// Provider can only read data for this metric.
  read,

  /// Provider can only write data for this metric.
  write,

  /// Provider can both read and write data for this metric.
  readWrite,
}

import 'package:json_annotation/json_annotation.dart';

/// Indicates whether a record was fetched live or served from cache.
@JsonEnum()
enum Freshness {
  /// Record was freshly fetched from the provider.
  live,

  /// Record was served from the local cache.
  cached,
}

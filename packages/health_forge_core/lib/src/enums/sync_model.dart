import 'package:json_annotation/json_annotation.dart';

/// How a provider synchronises data with the local store.
@JsonEnum()
enum SyncModel {
  /// Fetches all records within a requested time window each sync.
  fullWindow,

  /// Uses a cursor to fetch only new or updated records since last sync.
  incrementalCursor,

  /// Polls the provider at regular intervals for updates.
  polling,
}

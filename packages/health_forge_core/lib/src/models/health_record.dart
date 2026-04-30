import 'package:health_forge_core/src/enums/data_provider.dart';
import 'package:health_forge_core/src/enums/freshness.dart';
import 'package:health_forge_core/src/models/provenance.dart';

/// Envelope mixin applied to every health record type.
///
/// Provides a uniform set of metadata fields (id, provider, timestamps,
/// provenance, extensions) so that records can be processed generically.
mixin HealthRecordMixin {
  /// Unique identifier for this record.
  String get id;

  /// The data provider that produced this record.
  DataProvider get provider;

  /// Provider-specific record type identifier.
  String get providerRecordType;

  /// The native identifier assigned by the data provider.
  ///
  /// For HealthKit: the HKObject UUID. For Oura: the record ID.
  /// For Strava: the activity ID. Null if unavailable.
  String? get providerRecordId;

  /// Start of the measurement interval.
  DateTime get startTime;

  /// End of the measurement interval.
  DateTime get endTime;

  /// IANA timezone identifier, if available.
  String? get timezone;

  /// When this record was captured or ingested.
  DateTime get capturedAt;

  /// Optional provenance metadata (origin, device, source app).
  Provenance? get provenance;

  /// Whether this record was fetched live or served from cache.
  Freshness get freshness;

  /// Provider-specific extension data keyed by type.
  Map<String, dynamic> get extensions;

  /// The duration of the measurement interval.
  Duration get duration => endTime.difference(startTime);
}

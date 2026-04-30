import 'package:drift/drift.dart';

part 'health_cache_database.g.dart';

/// Table for cached health records stored as JSON blobs.
///
/// Each record is stored with indexed metadata columns for efficient
/// querying by provider, metric type, and time range. The full record
/// is preserved in [jsonPayload] for lossless deserialization.
///
/// A unique constraint on (provider, metricType, startTime, endTime,
/// sourceDeviceId) prevents duplicate records from the same source.
class CachedRecords extends Table {
  /// Auto-incrementing surrogate key.
  IntColumn get rowId => integer().autoIncrement()();

  /// Record ID assigned by the mapper (UUID v4).
  TextColumn get recordId => text()();

  /// The native identifier from the data provider, if available.
  TextColumn get providerRecordId => text().nullable()();

  /// The provider that sourced this record (e.g. "apple", "oura").
  TextColumn get provider => text()();

  /// The metric type name (e.g. "heartRate", "steps").
  TextColumn get metricType => text()();

  /// The runtime type name for deserialization (e.g. "HeartRateSample").
  TextColumn get recordType => text()();

  /// Start time of the measurement interval.
  DateTimeColumn get startTime => dateTime()();

  /// End time of the measurement interval.
  DateTimeColumn get endTime => dateTime()();

  /// Device identifier from provenance, or empty string if unknown.
  TextColumn get sourceDeviceId => text().withDefault(const Constant(''))();

  /// When the record was cached.
  DateTimeColumn get cachedAt => dateTime()();

  /// The full record serialized as JSON.
  TextColumn get jsonPayload => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {provider, metricType, startTime, endTime, sourceDeviceId},
      ];
}

/// Table for tracking sync metadata per provider/metric pair.
class SyncMetadata extends Table {
  /// The provider name.
  TextColumn get provider => text()();

  /// The metric type name.
  TextColumn get metricType => text()();

  /// When the last sync completed.
  DateTimeColumn get lastSyncTime => dateTime().nullable()();

  /// Cursor for incremental sync (e.g., Oura next_token).
  TextColumn get cursor => text().nullable()();

  @override
  Set<Column> get primaryKey => {provider, metricType};
}

/// Drift database for the health record cache.
@DriftDatabase(tables: [CachedRecords, SyncMetadata])
class HealthCacheDatabase extends _$HealthCacheDatabase {
  /// Creates a [HealthCacheDatabase] with the given query [executor].
  HealthCacheDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(cachedRecords, cachedRecords.providerRecordId);
        }
      },
    );
  }
}

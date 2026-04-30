# ADR 0006 — Cache Schema Design

## Status
Accepted

## Context
The `health_forge` Flutter package needs a local cache for health records. Records are polymorphic (21 types across 6 families), each with different fields. The cache must support efficient queries by provider, metric type, and time range.

## Decision

### JSON Blob Storage
Store each record as a JSON blob in a single `cached_records` table rather than normalized per-type tables. Reasons:

1. **Schema flexibility** — Adding new record types requires zero migration effort
2. **Polymorphism** — All 21 record types stored uniformly; no 21-table schema
3. **Aligned with freezed** — All models already have `toJson()`/`fromJson()` via code generation
4. **Query patterns** — Typical queries filter by provider + metric + time range, not by record-specific fields

### Table Design (Drift)
```
CachedRecords
├── id (TEXT, PK)          — HealthRecord.id
├── provider (TEXT)        — DataProvider name
├── metricType (TEXT)      — MetricType name
├── startTime (DATETIME)   — indexed for range queries
├── endTime (DATETIME)
├── jsonPayload (TEXT)     — full record JSON
└── cachedAt (DATETIME)    — cache freshness tracking

SyncMetadata
├── provider (TEXT, PK)    — composite key
├── metricType (TEXT, PK)  — composite key
├── lastSyncTime (DATETIME)
└── cursor (TEXT, nullable) — for incremental sync
```

### Indexing Strategy
- Composite index on `(provider, metricType, startTime)` for the primary query pattern
- `cachedAt` indexed for cache eviction queries

### Trade-offs
- **Pro:** Simple schema, zero migrations for new record types, fast writes
- **Con:** Cannot query record-specific fields (e.g., "heart rates > 100bpm") at the database level — must filter in Dart after deserialization
- **Mitigation:** Record-specific queries are rare in the aggregation use case; most queries are "give me all heart rate records from provider X in time range Y"

## Consequences
- CacheManager serializes records to JSON on write and deserializes on read
- A type registry maps MetricType → fromJson factory for deserialization
- Cache eviction operates on `cachedAt` timestamp
- Future: if record-specific queries become needed, can add indexed columns without breaking the JSON storage approach

# 0003. Configurable Conflict Resolution with Five Built-in Strategies

**Status:** Accepted  
**Date:** 2026-03-17  
**Amended:** 2026-03-20 — duplicate-detection subsection aligned with shipped `DuplicateDetector` behavior

## Context

When multiple providers report overlapping health data (e.g., Apple Watch and Oura both report sleep), the system must decide which records to keep. Different use cases need different resolution approaches — a clinical app may want the most granular data, while a wellness dashboard may prefer averaged values. The merge operation must be isolate-safe for background execution to avoid blocking the UI thread.

## Decision

Implement a pure Dart `MergeEngine` with configurable conflict resolution:

### Duplicate Detection

**Shipped behavior (v0.1.x):** `MergeEngine` partitions input records by **metric type** (each concrete record type maps to one `MetricType`). Within each partition, `DuplicateDetector` forms **time-overlap clusters**: two records are in the same cluster if any pair overlaps when each record’s end time is extended by `MergeConfig.timeOverlapThresholdSeconds` (default **300 seconds**). Non-overlapping records are singleton groups. This is intentionally simple and isolate-safe.

**Future enhancements (not yet implemented):** tighter duplicate matching may also consider provider-assigned IDs, numeric value similarity (see reserved `MergeConfig.valueSimilarityThreshold`), and device/source identity so overlapping windows from different devices are not merged blindly.

> **Note:** An earlier draft of this ADR described five duplicate-matching dimensions as implemented; that model remains the **design target** for detection, while the bullet above reflects what the library **does today**.

### Conflict Strategies

Five built-in strategies via `ConflictStrategy` enum:

1. **`priorityBased`** — developer-defined provider ordering per metric type. E.g., for sleep: Oura > Apple Watch > Health Connect
2. **`keepAll`** — preserve all records with source attribution. No data loss, consumer decides at query time
3. **`average`** — compute mean values for numeric metrics. Useful for aggregate views
4. **`mostGranular`** — select records with highest data resolution/sampling rate. Prefers 1-second HR intervals over 5-minute summaries
5. **`custom`** — developer-provided callback function for domain-specific logic

### Merge Output

`MergeResult` contains:

- **Resolved records** — the final deduplicated record set
- **Conflict report** — what was merged, dropped, or averaged, and why
- **Raw source records** — preserved for transparency and auditability

### Configuration

`MergeConfig` specifies:

- Default strategy for all metric types
- Per-metric strategy overrides
- Provider priority lists per metric type
- `timeOverlapThresholdSeconds` for duplicate clustering within a metric
- `valueSimilarityThreshold` (reserved for future duplicate refinement; not used by `DuplicateDetector` yet)

## Consequences

### Positive

- Transparent conflict resolution — every merge decision is auditable via the conflict report
- Developer control — strategies can be tuned per metric type
- Isolate-safe execution for background processing (pure Dart, no Flutter dependencies)
- `keepAll` strategy ensures zero data loss when the right resolution is unclear
- Extensible via custom callbacks for domain-specific needs

### Negative

- Complexity in testing all strategy combinations across metric types
- Custom callbacks break isolate safety — must run on the main isolate, limiting background merge performance
- Until value- and device-aware matching land, time-only clustering may group records that a human would treat as distinct (e.g., two devices reporting the same window)
- `average` strategy is only meaningful for numeric metrics; not applicable to categorical data like sleep stages
- Provider priority lists must be maintained as new providers are added

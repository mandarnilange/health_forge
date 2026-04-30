# 0002. Record Envelope via Mixin Pattern with DataOrigin Classification

**Status:** Accepted
**Date:** 2026-03-17

## Context

All health records need common metadata (id, provider, timestamps, provenance) for deduplication, caching, and conflict resolution. Using a base class conflicts with freezed's code generation — freezed classes cannot extend other freezed classes. Additionally, the system needs to classify how data was obtained to assign trust signals during conflict resolution.

## Decision

Use a mixin-based envelope pattern with a DataOrigin classification enum:

- **`HealthRecordMixin`** defines abstract getters for envelope fields:
  - `id` — unique record identifier
  - `provider` — source provider enum
  - `providerRecordType` — provider-native type name
  - `startTime`, `endTime` — temporal range
  - `timezone` — original timezone of measurement
  - `capturedAt` — when the record was fetched from the provider
  - `provenance` — source tracking metadata
  - `freshness` — cache staleness indicator
  - `extensions` — typed provider-specific data map

- Each concrete record is a `@freezed` class that `with HealthRecordMixin`

- **`Provenance`** tracks:
  - `sourceDevice` — hardware that captured the data
  - `sourceApp` — application that recorded it
  - `dataOrigin` — trust classification
  - `rawPayloadRef` — optional reference to the original provider payload

- **`DataOrigin`** enum classifies data trust level:
  - `native` — direct from device sensor (highest trust)
  - `mapped` — transformed from another format (e.g., FHIR to internal model)
  - `derived` — calculated from other records (e.g., HRV from RR intervals)
  - `estimated` — algorithmically inferred (e.g., VO2 max estimation)
  - `extracted` — from documents like lab reports or PDFs

- `Map<Type, ProviderExtension> extensions` allows typed provider-specific data attachment on any record

## Consequences

### Positive

- Compile-time enforcement of envelope fields across all record types
- Full freezed compatibility — no inheritance conflicts
- Rich provenance tracking enables informed conflict resolution
- DataOrigin provides clear trust hierarchy for merge decisions
- Extensible without modifying core record types
- Records remain immutable and serializable

### Negative

- Mixin fields must be manually included in each freezed factory constructor and JSON serialization — slight boilerplate per record class
- No inheritance-based polymorphism for records; list operations require mixin type
- DataOrigin assignment is provider-specific and must be correct at mapping time — misclassification degrades merge quality

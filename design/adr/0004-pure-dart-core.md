# 0004. Pure Dart Core Package with Zero Flutter Dependencies

**Status:** Accepted
**Date:** 2026-03-17

## Context

The merge engine processes potentially thousands of health records and must run on background isolates to avoid blocking the UI. Flutter plugins cannot run on isolates — they require access to the platform channel, which is bound to the main isolate. The core data models need to serialize/deserialize for isolate message passing. Additionally, server-side Dart applications (e.g., a backend health data aggregator) may want to reuse the data models and merge logic.

## Decision

`health_forge_core` depends only on pure Dart packages:

- `freezed_annotation` / `json_annotation` — code generation for models and JSON
- `meta` — annotations
- `uuid` — record identifier generation
- `collection` — advanced collection utilities
- `equatable` — value equality

### Enforcement

- Zero Flutter imports enforced by CI: automated grep for `dart:ui`, `package:flutter`, and any Flutter-dependent package in core's dependency tree
- Architecture test verifies the dependency constraint on every PR

### Design Constraints

- All models must implement `toJson()` / `fromJson()` for isolate serialization via `SendPort`/`ReceivePort`
- Merge engine designed as pure functions operating on immutable records — no mutable state, no singletons
- No `dart:io` usage in core to preserve web compatibility

## Consequences

### Positive

- Isolate-safe merge operations — entire merge pipeline can run in background without UI jank
- Potential server-side reuse — core models and merge logic work in Dart CLI, shelf, or dart_frog backends
- Minimal dependency tree — faster resolution, fewer version conflicts
- Fast test execution — no Flutter test runner needed, `dart test` runs in seconds
- Clean separation of concerns — forces platform-specific code into adapter packages

### Negative

- Cannot use Flutter-specific utilities (e.g., `ChangeNotifier`, `ValueNotifier`) in core
- Platform channel access is limited to adapter packages, requiring an abstraction boundary
- Some code duplication between core utilities and Flutter package equivalents
- Contributors must be vigilant about not accidentally introducing Flutter imports
- Web-compatible constraint means no `dart:io` for file operations in core

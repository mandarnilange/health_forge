# 0001. Federated Plugin Model for Multi-Provider Health Data

**Status:** Accepted
**Date:** 2026-03-17

## Context

health_forge needs to support multiple health data providers (HealthKit, Health Connect, Oura, Strava, Garmin). Developers should only pull dependencies they need. Each provider has different release cadences, API stability, and licensing constraints. A monolithic package would force every consumer to depend on every provider's native SDK, bloating app size and creating unnecessary coupling.

## Decision

Adopt Flutter's federated plugin pattern with melos for mono-repo management:

- **`health_forge_core`** — pure Dart: models, enums, interfaces, merge engine
- **`health_forge`** — Flutter package: registry, auth, queries, cache, isolate orchestration
- **`health_forge_{provider}`** — one package per provider (e.g., `health_forge_apple`, `health_forge_oura`), each depending only on core
- Each package is publishable independently to pub.dev with its own versioning
- melos manages the workspace: bootstrap, analyze, test, generate scripts
- Package boundary rule: provider packages depend on `health_forge_core` only, never on each other or on `health_forge`

## Consequences

### Positive

- Minimal dependency trees — consumers only pull what they use
- Independent versioning allows providers to release at their own cadence
- Isolated blast radius — a breaking change in one provider doesn't affect others
- Community can contribute new providers without touching core
- CI can test each package in isolation, speeding up feedback loops
- Licensing constraints of individual provider SDKs don't contaminate the full package

### Negative

- More packages to maintain, each with its own pubspec, changelog, and CI config
- Cross-package changes (e.g., adding a new envelope field) require coordinated releases
- melos workspace tooling has a learning curve for new contributors
- Version constraint management across packages adds overhead
- Local development requires `melos bootstrap` before first use

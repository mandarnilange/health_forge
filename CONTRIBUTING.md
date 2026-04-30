# Contributing to Health Forge

Thank you for your interest in contributing to Health Forge! This guide will help you get started.

## Development Setup

### Prerequisites

- Dart SDK >= 3.6.0
- Flutter >= 3.27.0
- Melos (`dart pub global activate melos`)

### Getting Started

```bash
git clone https://github.com/mandarnilange/health_forge_workspace.git
cd health_forge_workspace
dart pub get
dart run melos bootstrap
```

### Running Commands

```bash
dart run melos run analyze    # Lint all packages (zero warnings required)
dart run melos run test       # Run all tests
dart run melos run format     # Check formatting
dart run melos run generate   # Run code generation (freezed, json_serializable)
```

## Development Workflow

### Test-Driven Development (TDD)

All contributions must follow TDD:

1. Write a failing test that describes the expected behavior
2. Implement the minimum code to make the test pass
3. Refactor if needed, keeping tests green

### Code Quality Requirements

Before submitting a PR, ensure:

- All tests pass: `dart run melos run test`
- Zero lint warnings: `dart run melos run analyze`
- Code is formatted: `dart run melos run format`
- No Flutter imports in `health_forge_core` (must stay isolate-safe)
- All models use `@freezed` for immutability
- No GPL dependencies (MIT license only)

### Code Generation

If you modify `@freezed` or `@JsonSerializable` models, regenerate:

```bash
dart run melos run generate
```

Generated files (`*.g.dart`, `*.freezed.dart`) are gitignored and should not be committed.

## Making Changes

### Branching

- Create a feature branch from `main`: `git checkout -b feature/your-feature`
- Keep commits focused and atomic
- Write clear commit messages describing the "why"

### Architecture Decisions

If your change involves a technology choice, new pattern, folder structure change, or integration approach, document it as an Architecture Decision Record (ADR) in `design/adr/`. Use the next available number: `NNNN-short-title.md`.

### Pull Requests

- Keep PRs focused on a single concern
- Include tests for all new functionality
- Update documentation if the API surface changes:
  - `README.md` for package status or roadmap changes
  - `docs/getting_started.md` for user-facing API changes
- Fill out the PR template completely

## Package Structure

```
packages/
  health_forge_core/    # Pure Dart: models, enums, interfaces, merge engine
  health_forge/         # Flutter: registry, auth, queries, cache
  health_forge_apple/   # HealthKit adapter
  health_forge_ghc/     # Health Connect adapter
  health_forge_oura/    # Oura REST API adapter
  health_forge_strava/  # Strava REST API adapter
```

### Key Patterns

- **HealthRecordMixin**: All record types implement this envelope mixin
- **Type-safe extensions**: `Map<Type, ProviderExtension>` for provider-specific data
- **Platform-agnostic DTOs**: Adapter packages use `HealthDataRecord` for testability
- **Mappers**: Each adapter has mapper classes converting DTOs to core models

## Reporting Issues

- Use the issue templates for bug reports and feature requests
- For security vulnerabilities, see [SECURITY.md](SECURITY.md)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

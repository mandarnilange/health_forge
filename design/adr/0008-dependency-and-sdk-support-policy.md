# ADR 0008 — Dependency and SDK Support Policy

## Status

Accepted. Supersedes the `equatable` entry in ADR 0004's dependency list.

## Date

2026-09-23

## Context

The 0.3.0 dependency upgrade (see
`docs/specs/2026-09-23-dependency-upgrade.md`) raised questions we hadn't
written down:

- The published packages declared Dart `>=3.6.0` / Flutter `>=3.27.0`, but
  their dependencies had already raised the real minimum, so those floors no
  longer resolved.
- Dev tooling (`freezed` 4, `very_good_analysis` 11) needs a newer SDK than
  users of the packages do.
- `flutter_secure_storage` 11 is a major release with data-migration
  consequences for apps, and `health_forge` injects the app's own storage
  instance.
- `equatable` was listed as a core dependency but never imported.

## Decision

### Two SDK floors

1. **Published packages** declare the lowest SDK that their *runtime*
   dependencies allow. For 0.3.0 that is Dart `>=3.10.0` / Flutter
   `>=3.38.1` (drift 2.35, sqlite3, device_info_plus 13). Flutter 3.38.0 is
   excluded because it shipped a beta Dart. Dev dependencies don't count,
   because they never reach apps using the packages.
2. **The workspace** (root, example, unpublished packages) declares the
   contributor toolchain: Dart `>=3.13.0` / Flutter `>=3.47.0`, as documented
   in CONTRIBUTING.md.

The published floors are verified in CI by a job that pins Flutter at the
floor version. It copies the published packages out of the workspace, strips
the dev dependencies, and runs `pub get`, `pub downgrade` and `dart analyze`
on each. A second job runs the full test suite at the lowest allowed
dependency versions (`dart pub downgrade`).

### Dependency ranges

- Prefer caret ranges at the latest version.
- A dependency may span two majors (e.g. `flutter_secure_storage
  >=10.0.0 <12.0.0`) when the API we use is unchanged and forcing the new
  major would push a data migration onto apps. The CI downgrade job keeps the
  lower major working.
- Remove dependencies that aren't imported, rather than upgrading them.

### Internal constraints

Before 1.0, a caret range doesn't accept the next minor, so every release bumps
the `health_forge_core` constraint in the other published packages together
with the version numbers.

## Consequences

- Apps on Flutter 3.38.1–3.46 can use 0.3.0; contributors need Flutter 3.47.
- CI takes two extra jobs to run. The floor job can only analyze (compile)
  the packages at the floor, not run their tests, because the test tooling
  needs Dart 3.13.
- Removing `equatable` leaves freezed as the only source of value equality in
  core.

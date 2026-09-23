# Spec: Dependency upgrade (September 2026)

- **Status:** Implemented on `chore/dependency-upgrade-2026-09` (PR #11), including the 0.3.0 release prep
- **Date:** 2026-09-23
- **Target release:** 0.3.0, decided (see [Release impact](#release-impact))
- **Related:** #4 (Swift Package Manager migration), #10 (release automation)

## Summary

Bring every package in the workspace up to the latest dependency versions
that resolve on current Flutter stable (3.47.5 / Dart 3.13.4). Drop two
dependencies that are declared but never used, and set the declared SDK lower
bounds to what the dependency graph actually requires.

The full target set was checked in a scratch copy of the repo on 2026-09-23.
It resolves, and code generation runs cleanly (`freezed` 72 outputs,
`health_forge` 54 outputs). `dart analyze` reports 15 lint findings, and
`dart format` would change 16 files. All 914 tests pass (see
[Verification](#verification)).

## Current state

| Area | Current |
| --- | --- |
| Toolchain (local + CI `channel: stable`) | Flutter 3.47.5, Dart 3.13.4 |
| Declared SDK floors | `sdk: >=3.6.0` (core `>=3.8.0`), `flutter: >=3.27.0` |
| Lockfile-required SDK (actual) | Dart `>=3.11.0`, Flutter `>=3.38.4` |
| Example app | AGP 8.11.1, Kotlin 2.2.20, Gradle 8.14, minSdk 28, iOS 16.0 |
| CI actions | `actions/checkout@v4`, `subosito/flutter-action@v2`, `actions/upload-artifact@v4`, `softprops/action-gh-release@v2` |

The declared SDK floors are stale. The lockfile already needs Dart 3.11 and
Flutter 3.38.4, so a consumer on Flutter 3.27 can't resolve our published
packages today.

## Findings

### Direct dependencies

"Target" is the constraint to write. "Resolves to" is what pub picked in
the scratch run.

| Package | Where | Current | Latest | Target | Resolves to | Bump |
| --- | --- | --- | --- | --- | --- | --- |
| health | apple, ghc | ^13.3.1 | 13.3.2 | ^13.3.2 | 13.3.2 | patch (behavioural, see below) |
| drift | health_forge | ^2.32.0 | 2.35.0 | ^2.35.0 | 2.35.0 | minor |
| flutter_secure_storage | health_forge | ^10.0.0 | 11.2.0 | `>=10.0.0 <12.0.0` | 11.2.0 | **major** |
| dio | oura, strava, garmin | ^5.9.2 | 5.11.1 | ^5.11.1 | 5.11.1 | minor |
| crypto | oura, strava | ^3.0.6 | 3.0.7 | ^3.0.7 | 3.0.7 | patch |
| uuid | core | ^4.5.3 | 4.6.0 | ^4.6.0 | 4.6.0 | minor |
| json_annotation | core | ^4.11.0 | 4.12.0 | ^4.12.0 | 4.12.0 | minor (json_serializable 6.14 pins `<4.13`) |
| freezed_annotation | core | ^3.1.0 | 3.1.0 | unchanged | 3.1.0 | — |
| collection | core | ^1.19.1 | 1.19.1 | unchanged | 1.19.1 | — |
| equatable | core | ^2.0.8 | 3.0.0 | **remove** | — | not imported anywhere |
| app_links | example | ^7.0.0 | 7.2.1 | ^7.2.1 | 7.2.1 | minor (needs Flutter ≥3.44) |
| intl | example | ^0.20.2 | 0.20.3 | ^0.20.3 | 0.20.3 | patch |
| url_launcher | example | ^6.3.2 | 6.3.2 | unchanged | 6.3.2 | — |

### Dev dependencies

| Package | Current | Latest | Target | Resolves to | Bump |
| --- | --- | --- | --- | --- | --- |
| freezed | ^3.2.5 | 4.0.2 | ^4.0.1 | **4.0.1** | **major** (capped, see below) |
| build_runner | ^2.13.0 | 2.16.1 | ^2.16.1 | 2.16.1 | minor |
| json_serializable | ^6.13.0 | 6.14.1 | ^6.14.1 | 6.14.1 | minor |
| drift_dev | ^2.32.0 | 2.35.0 | ^2.35.0 | 2.35.0 | minor (must move with drift) |
| very_good_analysis | ^10.2.0 | 11.0.0 | ^11.0.0 | 11.0.0 | **major** |
| melos | ^7.4.1 | 8.9.0 | ^8.9.0 | 8.9.0 | **major** |
| test | ^1.25.0 | 1.32.0 | ^1.31.1 | **1.31.1** | minor (capped, see below) |
| mocktail | ^1.0.4 | 1.0.5 | ^1.0.5 | 1.0.5 | patch |
| lcov_parser | ^0.1.3 | 0.1.3 | unchanged | 0.1.3 | — |
| dlcov | ^4.2.1 | 4.2.1 (2022) | **remove** | — | unused; `tool/` uses only `lcov_parser` |

### Version caps set by the Flutter SDK

`flutter_test` pins `test_api` to 0.7.12. That limits how far the codegen
stack can move:

```
flutter_test (SDK) ─pins→ test_api 0.7.12
  → test ≤ 1.31.1            (1.31.2+ needs test_api 0.7.13/0.7.14)
    → analyzer < 14.0.0      (test 1.31.1 constraint)
      → freezed ≤ 4.0.1      (4.0.2 requires analyzer ≥ 14)
```

- **Resolved analyzer:** 13.3.0. drift_dev 2.35, json_serializable 6.14,
  build_runner 2.16 and source_gen 4.2.3 all accept it.
- **Caret constraints:** use `freezed: ^4.0.1` and `test: ^1.31.1`. Once a
  Flutter stable release bumps its `test_api` pin, `dart pub upgrade` will
  move to freezed 4.0.2, test 1.32 and analyzer 14 with no pubspec edits.
- **Why melos 8.9 failed alone:** melos 8.9 can't resolve on its own
  (`cli_util` conflict with old drift_dev). The conflict goes away once
  freezed 4 and drift_dev 2.35 move with it, so the three must be upgraded
  in the same step.

### Transitive majors pulled in

- **`health` 13.3.2** brings `device_info_plus` 12 → 13 and
  `carp_serializable` 2 → 3. Neither is used directly.
- **`flutter_secure_storage` 11** brings `flutter_secure_storage_darwin`
  0.2 → 0.4.3.
- **Other:** `win32` 5 → 6 and `sqlite3` 3.3 → 3.6.

### Breaking-change impact on this codebase

| Change | Upstream breaking change | Impact here |
| --- | --- | --- |
| equatable 2 → 3 | `EquatableMixin` removed. `==` no longer compares `runtimeType`. `toString` override removed. | **None.** It's declared in core but never imported, so the dependency is removed rather than upgraded. |
| freezed 3 → 4 | `final` in constructor params rejected. Primary constructors. Requires analyzer 13/14. | **Low.** 24 `@freezed` files, no `@unfreezed`, no `final` constructor params. Regenerates cleanly. |
| very_good_analysis 10 → 11 | 7 new lints. Formatter trailing-comma config. | **15 findings:** 13 × `async_return_with_no_await`, 2 × `unnecessary_ignore` (oura 8, core 2, health_forge 2, strava 2, example 1). `dart format` changes 16 files. |
| melos 7 → 8 | Scripts can no longer combine `run:` with `exec:`; the command moves to `exec.command`. Build numbers kept on version. `analyze` defaults to `--fatal-infos`. `nullsafety` filter removed. | **Low, but config change needed.** 5 scripts in the root `pubspec.yaml` (`analyze`, `test`, `test:coverage`, `test:dart`, `generate`) moved to `exec.command`. |
| flutter_secure_storage 10 → 11 | Deprecated v10 cipher options and `encryptedSharedPreferences` removed. Android minSdk 24. Data written with the removed ciphers can't be read. | **Consumer-facing.** `TokenStore` takes an injected `FlutterSecureStorage` and only uses read/write/delete, so our code is unaffected. Consumers who built storage with the removed v10 options lose stored OAuth tokens and must re-authenticate. The widened range `>=10.0.0 <12.0.0` lets them stay on 10 until they're ready. minSdk 24 is below `health`'s 26, so the floor doesn't change. |
| health 13.3.1 → 13.3.2 | iOS minimum 14.0 → 15.0. iOS class renamed `SwiftHealthPlugin` → `HealthPlugin`. Write methods return a UUID. Android is unchanged (`minSdk` 26, compile/target SDK 36 since 13.2.0). | **Low.** We only read (`getHealthDataFromTypes`, `requestAuthorization`, `hasPermissions`). HRV types (`HEART_RATE_VARIABILITY_SDNN` / `_RMSSD`) are unchanged. The example is already on iOS 16. Document iOS 15 for apple and `minSdk` 26 / `compileSdk` 36 for ghc (Health Connect itself needs Android 9 / API 28+). |

### Unblocks #4 (Swift Package Manager)

`health` has shipped `ios/health/Package.swift` since 13.1.4, with
swift-tools 5.9 and iOS 15.0. That was the only iOS plugin blocking the SPM
migration: `flutter_secure_storage_darwin` 0.4.3, `app_links`, `url_launcher_ios`
and `device_info_plus` already support SPM. **The SPM work is out of scope
for this spec** and should be a follow-up PR on #4 once this lands.

### CI actions

| Action | Pinned | Latest | Action |
| --- | --- | --- | --- |
| actions/checkout | v4 | v7.0.1 | bump to `@v7` |
| actions/upload-artifact | v4 | v7.0.1 | bump to `@v7` |
| softprops/action-gh-release | v2 | v3.0.3 | bump to `@v3` after reading the v3 release notes (`release.yaml` only) |
| subosito/flutter-action | v2 | v2.23.0 | no change (`@v2` floats) |

## Plan

Each step is its own commit. The workspace must pass
`melos run analyze`, `melos run format`, `melos run test` and
`coverage:verify` after every commit.

1. **Remove unused dependencies.** Drop `equatable` (core) and `dlcov`
   (root). No code changes.
2. **Apply the non-breaking bumps.** health, drift + drift_dev, dio, crypto,
   uuid, json_annotation, intl, app_links, mocktail, build_runner,
   json_serializable. Regenerate code.
3. **Upgrade the codegen stack.** `freezed ^4.0.1`, `test ^1.31.1` and
   `melos ^8.9.0` go in together, because they only resolve as a set.
   Regenerate, and run every melos script listed in `ci.yaml` locally.
4. **Upgrade to very_good_analysis 11.** Bump it, then fix the 15 lint
   findings. The `async_return_with_no_await` fixes (drop `async` or add
   `await`) must keep behaviour the same: existing tests are the guard, and
   tests are added first where a changed method isn't covered. Run
   `dart format` separately so the formatter churn is its own commit.
5. **Widen `flutter_secure_storage` to `>=10.0.0 <12.0.0`.** Existing
   `TokenStore` tests already cover read/write/delete by key, and a mock
   round-trip would only test the mock. The review instead found that
   Android's `resetOnError` sentinel (`"Data has been reset"`) could be
   returned as a token, so `TokenStore.read` now maps it to null (test
   added). Document the consumer migration note.
6. **Set SDK floors.** Set the published packages to the lowest SDK their
   runtime dependencies allow. drift 2.35 needs Dart ≥3.10, so the proposal is
   `sdk: ^3.10.0` and `flutter: ">=3.38.1"`. Flutter 3.38.0 shipped a
   beta Dart (`3.10.0-290.4.beta`), and 3.38.1 is the first release with
   stable Dart 3.10.0. These floors come from the dependency constraints
   (drift 2.35, sqlite3, device_info_plus 13 need Dart 3.10 / Flutter
   3.38.1). The workspace's dev tooling needs Dart 3.13 (noted in
   CONTRIBUTING.md), so the floor can't run the test suite. Instead, the CI
   job `sdk-floor` pins Flutter 3.38.1 and runs `tool/check_min_sdk.sh`,
   which copies the published packages out of the workspace without their
   dev dependencies, then resolves and analyzes each one at the latest and
   lowest allowed versions. A second job, `lowest-deps`, runs the full suite
   after `dart pub downgrade` on the current toolchain. The policy is
   recorded in ADR 0008.
7. **Bump CI actions** as listed in [CI actions](#ci-actions).
8. **Update docs and changelogs.** Per-package `CHANGELOG.md` entries,
   README minimum versions (iOS 15 / Android minSdk 26 for the health
   adapters), and CONTRIBUTING toolchain (Flutter ≥3.47 / Dart ≥3.13 for
   contributors).

## Verification

- **Scratch run (2026-09-23), target set:**
  - resolves (workspace needs Dart ≥3.13, which means Flutter ≥3.47)
  - `build_runner` succeeds for core and health_forge
  - analyze: 15 findings, all listed above
  - format: 16 files changed
  - tests: 914/914 pass, the same count as the baseline on `main`
    (core 369, health_forge 110, apple 68, ghc 69, oura 157, strava 107,
    example 34)
- **On the branch:**
  - analyze and format clean
  - tests: 938/938 pass. That's the 914 baseline plus 24 added during PR
    review: 21 drift cache round-trip tests covering all 20 record types,
    1 `TokenStore` reset-sentinel test, and 2 token-exchange failure tests
    (oura, strava)
  - coverage: 92.3–99.7% per package, all above the 90% gate
  - downgrade check: `dart pub downgrade` → analyze + tests pass at the
    lowest allowed versions (including `flutter_secure_storage` 10.0.0)
- **Per commit:** analyze, format, tests and ≥90% per-package coverage
  (the existing CI gates).
- **Device check:** run the example app on an iOS device and an Android
  device through `docs/device_testing_checklist.md` before release. Health
  reads and Oura/Strava OAuth token persistence are the areas touched.

## Release impact

- **Version: 0.3.0** for all published packages (decided). Raising the SDK
  floor and allowing `flutter_secure_storage` 11 change what consumers
  resolve, and pre-1.0 convention puts that in a minor bump.
- **Bump internal constraints too (done).** `health_forge`, `health_forge_apple`,
  `health_forge_ghc`, `health_forge_oura` and `health_forge_strava` depended
  on `health_forge_core: ^0.2.0`. Before 1.0, a caret range doesn't accept 0.3.0,
  so change those constraints to `^0.3.0` in the same release commit as the
  version bumps. Otherwise the adapters won't resolve against the new core.
- **Publishing depends on #10:** release once automated publishing (#10) is
  fixed; until then, the packages have to be published manually.

## Out of scope

- The SPM migration (#4). It's unblocked by this work but tracked separately.
- The example app's Android toolchain (AGP, Kotlin, Gradle). Handle in a
  separate PR if `flutter build apk` on 3.47 warns.
- freezed 4.0.2 / test 1.32 / analyzer 14. They're blocked by the Flutter
  SDK's `test_api` pin and will come through `pub upgrade` automatically.
- `health_forge_garmin` / `health_forge_labs` (unpublished, not in the
  workspace list). They only get constraint bumps: `very_good_analysis` 11
  and Dart ≥3.13 in both; `dio`, `mocktail` and Flutter ≥3.47 in garmin;
  `test` in labs.

## Decisions

1. **Version: 0.3.0** for all six published packages. The internal
   `health_forge_core` constraints moved to `^0.3.0` in the same change.
2. **`flutter_secure_storage` stays at `>=10.0.0 <12.0.0`.** Fresh installs
   get v11. Apps that pin v10 through other dependencies still resolve. The
   migration note is in the `health_forge` README ("Upgrading to 0.3.0") and
   CHANGELOG.

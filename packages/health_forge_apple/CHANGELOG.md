## 0.3.0

- **Breaking:** minimum SDK raised to Dart 3.10 / Flutter 3.38.1.
- **Breaking:** upgraded `health` to `^13.3.2`, which requires **iOS 15.0**
  or later.
- Bumped `health_forge_core` dependency to `^0.3.0`.

## 0.2.0

- Bumped `health_forge_core` dependency to `^0.2.0`
  (`HeartRateVariability.sdnnMilliseconds` is now nullable). Apple HealthKit
  still reports SDNN, so the mapper is unchanged.

## 0.1.1

- Added `example/example.dart` demonstrating `AppleHealthProvider`
  construction and capability inspection
- Added `example/README.md` linking to the workspace Flutter example app
- Bumped `health_forge_core` dependency to `^0.1.1`

## 0.1.0

- Initial release
- Apple HealthKit adapter supporting 14 health metric types
- Mappers for activity, heart rate, sleep, body, and respiratory data
- Platform-agnostic HealthDataRecord DTO for testability
- See [getting started guide](https://github.com/mandarnilange/health_forge/blob/main/docs/getting_started.md) for usage
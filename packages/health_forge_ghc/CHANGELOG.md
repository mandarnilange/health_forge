## 0.2.0

- **Fixed:** map `MetricType.hrv` to `HEART_RATE_VARIABILITY_RMSSD` instead of
  the HealthKit-only `HEART_RATE_VARIABILITY_SDNN`. Health Connect does not
  support SDNN, which caused the native permission request to abort with
  `success(false)` before the dialog appeared — blocking authorization for
  every metric, not just HRV.
- HRV records now populate `rmssdMilliseconds` (Health Connect reports RMSSD).
- Bumped `health_forge_core` dependency to `^0.2.0`.

## 0.1.1

- Added `example/example.dart` demonstrating `GhcHealthProvider`
  construction and capability inspection
- Added `example/README.md` linking to the workspace Flutter example app
- Bumped `health_forge_core` dependency to `^0.1.1`

## 0.1.0

- Initial release
- Google Health Connect adapter supporting 14 health metric types
- Mappers for activity, heart rate, sleep, body, and respiratory data
- Platform-agnostic HealthDataRecord DTO for testability
- See [getting started guide](https://github.com/mandarnilange/health_forge/blob/main/docs/getting_started.md) for usage
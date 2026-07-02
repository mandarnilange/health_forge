## 0.2.0

- **Breaking:** `HeartRateVariability.sdnnMilliseconds` is now nullable
  (`double?`). Not every provider reports SDNN — Google Health Connect reports
  RMSSD instead. At least one of `sdnnMilliseconds` or `rmssdMilliseconds` must
  be present. This is enforced by a debug/profile-only assertion (Dart strips
  `assert`s from release builds); the built-in provider mappers always populate
  exactly one of the two.

## 0.1.1

- Added `example/example.dart` demonstrating the merge engine with two
  overlapping heart-rate samples
- Added `example/README.md` describing how to run the example
- Shortened pubspec description for cleaner pub.dev display

## 0.1.0

- Initial release
- 21 health record types across 6 families (activity, cardiovascular, sleep, recovery, respiratory, body)
- 7 enum types for type-safe health data classification
- HealthRecordMixin envelope with provider, timestamps, provenance, and extension slots
- Provider interfaces: HealthProvider, ProviderCapabilities, AuthResult
- MergeEngine with 5 conflict resolution strategies
- DuplicateDetector: time-overlap clustering within each metric type (`timeOverlapThresholdSeconds`)
- Provider extensions: OuraSleepExtension, StravaWorkoutExtension, GarminSleepExtension
- See [getting started guide](https://github.com/mandarnilange/health_forge/blob/main/docs/getting_started.md) for usage
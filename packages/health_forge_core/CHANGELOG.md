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

## 0.1.1

- Added `example/example.dart` demonstrating OAuth 2.0 PKCE setup
- Tightened pubspec description to satisfy pana length limit

## 0.1.0

- Initial release
- Strava REST API adapter supporting 5 health metric types (workouts, heart rate, calories, distance, elevation)
- OAuth 2.0 PKCE authentication with client_secret support
- Page-based pagination and dual rate limiting (100/15min + 1000/day)
- StravaWorkoutExtension for Strava-specific workout metrics (suffer score, segments, polyline)
- kJ to kcal conversion for calories, time-offset streams for heart rate
- See [getting started guide](https://github.com/mandarnilange/health_forge/blob/main/docs/getting_started.md) for usage
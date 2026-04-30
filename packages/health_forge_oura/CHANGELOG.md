## 0.1.1

- Added `example/example.dart` demonstrating OAuth 2.0 PKCE setup
- Shortened pubspec description for cleaner pub.dev display

## 0.1.0

- Initial release
- Oura Ring REST API adapter supporting 8 health metric types
- OAuth 2.0 PKCE authentication with automatic token refresh
- 7 API endpoint mappers: sleep, sleep score, activity, heart rate, readiness, stress, SpO2
- Automatic pagination via next_token and rate limiting (5 req/sec)
- OuraSleepExtension for Oura-specific sleep metrics
- See [getting started guide](https://github.com/mandarnilange/health_forge/blob/main/docs/getting_started.md) for usage
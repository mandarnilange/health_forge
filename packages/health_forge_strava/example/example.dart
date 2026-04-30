// Examples print to stdout for demonstration purposes only.
// ignore_for_file: avoid_print

import 'package:health_forge_strava/health_forge_strava.dart';

/// Wires up the Strava adapter with OAuth 2.0 PKCE.
///
/// Strava requires a client secret even with PKCE. For production, perform
/// the token exchange on a backend via `StravaTokenExchange` so the secret
/// never ships in the app binary. The development path below uses a direct
/// `clientSecret` call — fine for local testing, not for release builds.
void main() {
  final authManager = StravaAuthManager(
    clientId: 'YOUR_STRAVA_CLIENT_ID',
    clientSecret: 'YOUR_STRAVA_CLIENT_SECRET',
    redirectUri: 'healthforge://strava/callback',
    urlLauncher: (authUrl) async {
      // In a real app: launch the browser and await the deep-link callback.
      print('Open in browser: $authUrl');
      return null;
    },
  );

  final apiClient = StravaApiClient(authManager: authManager);
  final provider = StravaHealthProvider(
    authManager: authManager,
    apiClient: apiClient,
  );

  final metrics = provider.capabilities.supportedMetrics;
  print('${provider.displayName} supports ${metrics.length} metric type(s).');
}

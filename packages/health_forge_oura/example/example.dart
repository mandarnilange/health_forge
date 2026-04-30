// Examples print to stdout for demonstration purposes only.
// ignore_for_file: avoid_print

import 'package:health_forge_oura/health_forge_oura.dart';

/// Wires up the Oura Ring adapter with OAuth 2.0 PKCE.
///
/// Replace the `clientId` and `redirectUri` with values from your registered
/// app at https://cloud.ouraring.com/oauth/applications. The `urlLauncher`
/// callback opens the auth URL in the user's browser and returns the
/// redirect-callback URL once they complete the flow.
void main() {
  final authManager = OuraAuthManager(
    clientId: 'YOUR_OURA_CLIENT_ID',
    redirectUri: 'healthforge://oura/callback',
    urlLauncher: (authUrl) async {
      // In a real app: launch the browser and await the deep-link callback.
      print('Open in browser: $authUrl');
      return null;
    },
  );

  final apiClient = OuraApiClient(authManager: authManager);
  final provider = OuraHealthProvider(
    authManager: authManager,
    apiClient: apiClient,
  );

  final metrics = provider.capabilities.supportedMetrics;
  print('${provider.displayName} supports ${metrics.length} metric type(s).');
}

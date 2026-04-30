import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:health_forge/health_forge.dart';
import 'package:health_forge_apple/health_forge_apple.dart';
import 'package:health_forge_example/mock/mock_apple_provider.dart';
import 'package:health_forge_example/mock/mock_oura_provider.dart';
import 'package:health_forge_example/mock/mock_strava_provider.dart';
import 'package:health_forge_example/oauth_helper.dart';
import 'package:health_forge_example/screens/data_browser_screen.dart';
import 'package:health_forge_example/screens/home_screen.dart';
import 'package:health_forge_example/screens/provider_status_screen.dart';
import 'package:health_forge_ghc/health_forge_ghc.dart';
import 'package:health_forge_oura/health_forge_oura.dart';
import 'package:health_forge_strava/health_forge_strava.dart';

// TODO(mandar): Replace with actual Oura developer portal credentials.
const _ouraClientId = 'YOUR_OURA_CLIENT_ID';
const _ouraRedirectUri = 'healthforge://oura/callback';

// TODO(mandar): Replace with actual Strava developer portal credentials.
const _stravaClientId = 'YOUR_STRAVA_CLIENT_ID';
const _stravaClientSecret = 'YOUR_STRAVA_CLIENT_SECRET';
const _stravaRedirectUri = 'healthforge://strava/callback';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Set<DataProvider> authorizedProviders;

  // Use keepAll for high-frequency sample metrics so the merge engine
  // preserves every reading. Apple Watch records steps and HR in small
  // increments that collide with the default 300 s overlap threshold.
  final client = HealthForgeClient(
    mergeConfig: const MergeConfig(
      perMetricStrategy: {
        MetricType.steps: ConflictStrategy.keepAll,
        MetricType.heartRate: ConflictStrategy.keepAll,
        MetricType.calories: ConflictStrategy.keepAll,
        MetricType.distance: ConflictStrategy.keepAll,
        MetricType.elevation: ConflictStrategy.keepAll,
        MetricType.bloodOxygen: ConflictStrategy.keepAll,
        MetricType.bloodGlucose: ConflictStrategy.keepAll,
        MetricType.bloodPressure: ConflictStrategy.keepAll,
        MetricType.hrv: ConflictStrategy.keepAll,
        MetricType.restingHeartRate: ConflictStrategy.keepAll,
        MetricType.respiratoryRate: ConflictStrategy.keepAll,
        MetricType.workout: ConflictStrategy.keepAll,
      },
    ),
  );
  OAuthHelper? oauthHelper;

  // Use real platform providers on iOS/Android, mocks elsewhere.
  if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
    // Platform health provider
    if (Platform.isIOS) {
      client.use(AppleHealthProvider());
    } else {
      client.use(GhcHealthProvider());
    }

    // Real Oura + Strava with OAuth deep-link handling
    oauthHelper = OAuthHelper();

    final ouraAuth = OuraAuthManager(
      clientId: _ouraClientId,
      redirectUri: _ouraRedirectUri,
      urlLauncher: oauthHelper.launch,
    );
    final ouraApi = OuraApiClient(authManager: ouraAuth);
    client.use(OuraHealthProvider(authManager: ouraAuth, apiClient: ouraApi));

    final stravaAuth = StravaAuthManager(
      clientId: _stravaClientId,
      clientSecret: _stravaClientSecret,
      redirectUri: _stravaRedirectUri,
      urlLauncher: oauthHelper.launch,
    );
    final stravaApi = StravaApiClient(authManager: stravaAuth);
    client.use(
      StravaHealthProvider(authManager: stravaAuth, apiClient: stravaApi),
    );

    // Auto-authorize the platform health provider (shows the system
    // permission prompt on first launch). Oura/Strava require explicit
    // user-initiated OAuth so they stay manual via the Providers screen.
    final platformProvider =
        Platform.isIOS ? DataProvider.apple : DataProvider.googleHealthConnect;
    final authResult = await client.auth.authorize(platformProvider);
    authorizedProviders = {
      if (authResult.isSuccess) platformProvider,
    };
  } else {
    // Desktop, web, or simulator fallback — use mocks.
    client
      ..use(MockAppleProvider())
      ..use(MockOuraProvider())
      ..use(MockStravaProvider());
    final results = await client.auth.authorizeAll();
    authorizedProviders = {
      for (final e in results.entries)
        if (e.value.isSuccess) e.key,
    };
  }

  runApp(
    HealthForgeExampleApp(
      client: client,
      oauthHelper: oauthHelper,
      authorizedProviders: authorizedProviders,
    ),
  );
}

class HealthForgeExampleApp extends StatefulWidget {
  const HealthForgeExampleApp({
    required this.client,
    required this.authorizedProviders,
    this.oauthHelper,
    super.key,
  });

  final HealthForgeClient client;
  final OAuthHelper? oauthHelper;
  final Set<DataProvider> authorizedProviders;

  @override
  State<HealthForgeExampleApp> createState() => _HealthForgeExampleAppState();
}

class _HealthForgeExampleAppState extends State<HealthForgeExampleApp> {
  @override
  void dispose() {
    widget.oauthHelper?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Forge Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: _MainScaffold(
        client: widget.client,
        authorizedProviders: widget.authorizedProviders,
      ),
    );
  }
}

class _MainScaffold extends StatefulWidget {
  const _MainScaffold({
    required this.client,
    required this.authorizedProviders,
  });

  final HealthForgeClient client;
  final Set<DataProvider> authorizedProviders;

  @override
  State<_MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<_MainScaffold> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        HomeScreen(client: widget.client),
        ProviderStatusScreen(
          client: widget.client,
          authorizedProviders: widget.authorizedProviders,
        ),
        DataBrowserScreen(client: widget.client),
      ][_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices),
            label: 'Providers',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Browse',
          ),
        ],
      ),
    );
  }
}

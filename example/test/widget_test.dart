import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_forge/health_forge.dart';
import 'package:health_forge_example/main.dart';
import 'package:health_forge_example/mock/mock_apple_provider.dart';
import 'package:health_forge_example/mock/mock_oura_provider.dart';
import 'package:health_forge_example/mock/mock_strava_provider.dart';

/// Creates a client with mock providers (not authorized).
/// HomeScreen will stay in loading state, avoiding expensive sync.
HealthForgeClient _createClient() {
  return HealthForgeClient()
    ..use(MockAppleProvider())
    ..use(MockOuraProvider())
    ..use(MockStravaProvider());
}

void main() {
  group('HealthForgeExampleApp', () {
    testWidgets('launches and shows navigation bar', (tester) async {
      final client = _createClient();

      await tester.pumpWidget(
        HealthForgeExampleApp(
          client: client,
          authorizedProviders: const {},
        ),
      );
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('shows dashboard title', (tester) async {
      final client = _createClient();

      await tester.pumpWidget(
        HealthForgeExampleApp(
          client: client,
          authorizedProviders: const {},
        ),
      );
      await tester.pump();

      expect(find.text('Health Dashboard'), findsOneWidget);
    });

    testWidgets('navigates to provider status screen', (tester) async {
      final client = _createClient();

      await tester.pumpWidget(
        HealthForgeExampleApp(
          client: client,
          authorizedProviders: const {},
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Providers'));
      // Multiple pumps to let async checkAll() + setState complete
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Apple Health (Mock)'), findsOneWidget);
      expect(find.text('Oura Ring (Mock)'), findsOneWidget);
      expect(find.text('Strava (Mock)'), findsOneWidget);
    });

    testWidgets('navigates to browse screen', (tester) async {
      final client = _createClient();

      await tester.pumpWidget(
        HealthForgeExampleApp(
          client: client,
          authorizedProviders: const {},
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Browse'));
      await tester.pump();

      expect(find.text('Browse Data'), findsOneWidget);
    });
  });
}

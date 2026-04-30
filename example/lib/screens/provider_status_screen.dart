import 'dart:async';

import 'package:flutter/material.dart';
import 'package:health_forge/health_forge.dart';

import 'package:health_forge_example/widgets/provider_status_tile.dart';

class ProviderStatusScreen extends StatefulWidget {
  const ProviderStatusScreen({
    required this.client,
    this.authorizedProviders = const {},
    super.key,
  });

  final HealthForgeClient client;

  /// Providers already authorized at startup (e.g. Apple Health via auto-auth).
  /// Seed this from main() so the UI doesn't depend on the unreliable
  /// `hasPermissions` call for initial state.
  final Set<DataProvider> authorizedProviders;

  @override
  State<ProviderStatusScreen> createState() => _ProviderStatusScreenState();
}

class _ProviderStatusScreenState extends State<ProviderStatusScreen> {
  Map<DataProvider, bool> _statuses = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadStatuses());
  }

  Future<void> _loadStatuses() async {
    final statuses = await widget.client.auth.checkAll();

    // Overlay the startup-authorized providers on top of checkAll results,
    // because iOS HealthKit's hasPermissions is unreliable (always returns
    // null/false for read permissions due to privacy restrictions).
    for (final p in widget.authorizedProviders) {
      statuses[p] = true;
    }

    if (!mounted) return;
    setState(() {
      _statuses = statuses;
      _loading = false;
    });
  }

  Future<void> _toggle(HealthProvider provider) async {
    final isConnected = _statuses[provider.providerType] ?? false;
    if (isConnected) {
      await widget.client.auth.deauthorize(provider.providerType);
      if (!mounted) return;
      setState(() => _statuses[provider.providerType] = false);
    } else {
      final result = await widget.client.auth.authorize(provider.providerType);
      if (!mounted) return;
      setState(() => _statuses[provider.providerType] = result.isSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final providers = widget.client.registry.all;

    return Scaffold(
      appBar: AppBar(title: const Text('Providers')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: providers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final provider = providers[index];
                final connected = _statuses[provider.providerType] ?? false;
                return ProviderStatusTile(
                  provider: provider,
                  isConnected: connected,
                  onToggle: () => _toggle(provider),
                );
              },
            ),
    );
  }
}

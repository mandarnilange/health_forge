import 'package:flutter/material.dart';
import 'package:health_forge_core/health_forge_core.dart';

class ProviderStatusTile extends StatelessWidget {
  const ProviderStatusTile({
    required this.provider,
    required this.isConnected,
    required this.onToggle,
    super.key,
  });

  final HealthProvider provider;
  final bool isConnected;
  final VoidCallback onToggle;

  IconData _iconForProvider(DataProvider type) {
    return switch (type) {
      DataProvider.apple => Icons.apple,
      DataProvider.oura => Icons.ring_volume,
      DataProvider.googleHealthConnect => Icons.health_and_safety,
      DataProvider.strava => Icons.directions_bike,
      DataProvider.garmin => Icons.watch,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        _iconForProvider(provider.providerType),
        color: theme.colorScheme.primary,
      ),
      title: Text(provider.displayName),
      subtitle: Text(
        '${provider.capabilities.supportedMetrics.length} metrics supported',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(isConnected ? 'Connected' : 'Disconnected'),
            backgroundColor: isConnected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.errorContainer,
            labelStyle: TextStyle(
              color: isConnected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: onToggle,
            child: Text(isConnected ? 'Disconnect' : 'Connect'),
          ),
        ],
      ),
    );
  }
}

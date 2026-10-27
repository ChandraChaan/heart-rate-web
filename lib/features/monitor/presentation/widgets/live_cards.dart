import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/heart_rate_zones.dart';
import '../labels.dart';
import '../monitor_controller.dart';

/// Sensor name, demo badge, connection status, battery and location.
class DeviceBar extends ConsumerWidget {
  const DeviceBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final live = ref.watch(monitorProvider);
    if (live is! MonitorLive) return const SizedBox.shrink();
    final battery = live.batteryPercent;
    final location = live.location;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(live.deviceName, style: Theme.of(context).textTheme.titleMedium),
        if (live.simulated)
          Chip(
            key: const Key('simulated-badge'),
            avatar: Icon(Icons.science, size: 18, color: scheme.onTertiary),
            label: Text(l10n.simulatedBadge),
            labelStyle: TextStyle(
              color: scheme.onTertiary,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: scheme.tertiary,
            side: BorderSide.none,
          ),
        _StatusChip(status: live.status),
        if (battery != null)
          Chip(
            avatar: Icon(
              battery <= 15 ? Icons.battery_alert : Icons.battery_std,
              size: 18,
              color: battery <= 15 ? scheme.error : null,
            ),
            label: Text(l10n.batteryLabel(battery)),
          ),
        if (location != null)
          Chip(
            avatar: const Icon(Icons.accessibility_new, size: 18),
            label: Text(l10n.locationName(location)),
          ),
        if (live.status == LinkStatus.lost)
          FilledButton.tonalIcon(
            key: const Key('reconnect'),
            onPressed: () => ref.read(monitorProvider.notifier).reconnect(),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.reconnectButton),
          ),
        TextButton.icon(
          key: const Key('disconnect'),
          onPressed: () => ref.read(monitorProvider.notifier).disconnect(),
          icon: const Icon(Icons.bluetooth_disabled),
          label: Text(l10n.disconnectButton),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final LinkStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (icon, label, color) = switch (status) {
      LinkStatus.connected => (
        Icons.bluetooth_connected,
        l10n.statusConnected,
        scheme.primary,
      ),
      LinkStatus.reconnecting => (
        Icons.bluetooth_searching,
        l10n.statusReconnecting,
        scheme.tertiary,
      ),
      LinkStatus.lost => (
        Icons.bluetooth_disabled,
        l10n.statusLost,
        scheme.error,
      ),
    };
    return Chip(
      key: Key('status-${status.name}'),
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
    );
  }
}

/// The big number, the zone it's in, and a warning when the strap loses
/// skin contact.
class BpmCard extends ConsumerWidget {
  const BpmCard({required this.maxHr, super.key});

  final int maxHr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final live = ref.watch(monitorProvider);
    if (live is! MonitorLive) return const SizedBox.shrink();
    final latest = live.latest;
    final valid = latest != null && latest.isValid;
    final zone = valid ? HeartRateZones(maxHr).zoneOf(latest.bpm) : null;
    final zoneColor = zone == null
        ? null
        : ZoneColors.fromContext(context).of(zone);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Icon(
                  Icons.favorite,
                  color: valid
                      ? theme.colorScheme.primary
                      : theme.disabledColor,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: FittedBox(
                    child: Text(
                      valid ? '${latest.bpm}' : l10n.noValue,
                      key: const Key('bpm'),
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 96,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(l10n.bpmUnit, style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            if (zone != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: zoneColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.zoneName(zone),
                      key: const Key('zone'),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              )
            else if (latest == null)
              Text(l10n.waitingForData),
            if (live.contactLost) ...[
              const SizedBox(height: 12),
              _ContactWarning(message: l10n.contactWarning),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactWarning extends StatelessWidget {
  const _ContactWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('contact-warning'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small titled value, such as HRV or energy.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.title,
    required this.value,
    this.caption,
    super.key,
  });

  final String title;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = this.caption;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.headlineSmall),
            if (caption != null) ...[
              const SizedBox(height: 4),
              Text(
                caption,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// HRV from the last minute of RR-intervals, and energy if the strap sends
/// it.
class LiveStatTiles extends ConsumerWidget {
  const LiveStatTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final live = ref.watch(monitorProvider);
    if (live is! MonitorLive) return const SizedBox.shrink();
    final rmssd = live.rmssdMs;
    final energy = live.latest?.energyKj;
    final hrv = StatTile(
      key: const Key('hrv'),
      title: l10n.hrvTitle,
      value: rmssd != null ? l10n.hrvValue(rmssd.round()) : l10n.noValue,
      caption: !live.sendsRrIntervals
          ? (live.samples.isEmpty ? l10n.hrvCollecting : l10n.hrvNotSent)
          : rmssd == null
          ? l10n.hrvCollecting
          : l10n.hrvHelp,
    );
    if (energy == null) return hrv;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: hrv),
        const SizedBox(width: 12),
        Expanded(
          child: StatTile(
            title: l10n.energyTitle,
            value: l10n.energyValue(energy),
          ),
        ),
      ],
    );
  }
}

/// Demo mode only: buttons that make the simulated strap misbehave.
class DemoControls extends ConsumerWidget {
  const DemoControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final live = ref.watch(monitorProvider);
    if (live is! MonitorLive || !live.simulated) return const SizedBox.shrink();
    final controller = ref.read(monitorProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.demoControlsTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const Key('demo-contact'),
                  onPressed: () => controller.setSimulatedSkinContact(
                    !live.skinContactSimulated,
                  ),
                  child: Text(
                    live.skinContactSimulated
                        ? l10n.demoTakeOff
                        : l10n.demoPutOn,
                  ),
                ),
                OutlinedButton(
                  key: const Key('demo-drop'),
                  onPressed: live.status == LinkStatus.connected
                      ? controller.simulateDrop
                      : null,
                  child: Text(l10n.demoDrop),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

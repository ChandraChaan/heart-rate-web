import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../sessions/presentation/live_stats.dart';
import '../../sessions/presentation/recorder_controller.dart';
import '../../sessions/presentation/widgets/recording_bar.dart';
import 'monitor_controller.dart';
import 'widgets/connect_panel.dart';
import 'widgets/heart_rate_chart.dart';
import 'widgets/live_cards.dart';
import 'widgets/zone_time_bars.dart';

/// The Live tab: connect, then watch heart rate, zones and HRV.
class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(
      monitorProvider.select((state) => state is MonitorLive),
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [connected ? const _Dashboard() : const ConnectPanel()],
        ),
      ),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final simulated = ref.watch(
      monitorProvider.select(
        (state) => state is MonitorLive && state.simulated,
      ),
    );
    final maxHr = ref.watch(liveMaxHrProvider);

    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BpmCard(maxHr: maxHr),
        const SizedBox(height: 12),
        const LiveStatTiles(),
        const SizedBox(height: 12),
        const RecordingBar(),
        if (simulated) ...[const SizedBox(height: 12), const DemoControls()],
      ],
    );
    final charts = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _LiveChartCard(),
        const SizedBox(height: 12),
        _ZonesCard(maxHr: maxHr),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (simulated) ...[
          Card(
            key: const Key('simulated-banner'),
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: ListTile(
              leading: const Icon(Icons.science_outlined),
              title: Text(l10n.simulatedBanner),
              textColor: Theme.of(context).colorScheme.onTertiaryContainer,
              iconColor: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: 12),
        ],
        const DeviceBar(),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= 840
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: summary),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: charts),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [summary, const SizedBox(height: 12), charts],
                ),
        ),
      ],
    );
  }
}

class _LiveChartCard extends ConsumerWidget {
  const _LiveChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final live = ref.watch(monitorProvider);
    final maxHr = ref.watch(liveMaxHrProvider);
    if (live is! MonitorLive) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Text(
                l10n.chartTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(
              height: 260,
              child: HeartRateChart(
                samples: live.samples,
                maxHr: maxHr,
                window: const Duration(minutes: 3),
                semanticLabel: l10n.chartSemantics(live.latest?.bpm ?? 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZonesCard extends ConsumerWidget {
  const _ZonesCard({required this.maxHr});

  final int maxHr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stats = ref.watch(liveStatsProvider);
    final recording = ref.watch(recorderProvider) is RecorderRecording;
    if (stats == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.timeInZonesTitle, style: theme.textTheme.titleMedium),
            Text(
              '${recording ? l10n.timeInZonesRecording : l10n.timeInZonesSinceConnect}'
              ' · ${l10n.maxHrNote(maxHr)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ZoneTimeBars(timeInZones: stats.timeInZones, maxHr: maxHr),
          ],
        ),
      ),
    );
  }
}

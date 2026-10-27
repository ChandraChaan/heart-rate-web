import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/formatting.dart';
import '../../../l10n/app_localizations.dart';
import '../../monitor/presentation/widgets/heart_rate_chart.dart';
import '../../monitor/presentation/widgets/live_cards.dart';
import '../../monitor/presentation/widgets/zone_time_bars.dart';
import '../domain/recorded_session.dart';
import '../domain/session_stats.dart';
import '../domain/tcx_export.dart';
import 'sessions_controller.dart';

/// Summary of one recording, with export and delete.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider(sessionId));
    final stats = ref.watch(sessionStatsProvider(sessionId));
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          session == null
              ? l10n.sessionTitle
              : DateFormat.yMMMEd(
                  locale,
                ).add_Hm().format(session.startedAt.toLocal()),
        ),
        actions: [
          if (session != null)
            IconButton(
              key: const Key('delete-session'),
              tooltip: l10n.deleteButton,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref, session),
            ),
        ],
      ),
      body: session == null || stats == null
          ? Center(child: Text(l10n.sessionNotFound))
          : _Summary(session: session, stats: stats),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RecordedSession session,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text(l10n.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm-delete'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    await ref.read(sessionsProvider.notifier).delete(session.id);
    messenger.showSnackBar(SnackBar(content: Text(l10n.sessionDeleted)));
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.session, required this.stats});

  final RecordedSession session;
  final SessionStats stats;

  Future<void> _export(
    BuildContext context,
    Future<void> Function() export,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await export();
    } on UnsupportedError {
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String bpm(int? value) =>
        value == null ? l10n.noValue : l10n.bpmValue(value);
    final rmssd = stats.rmssdMs;
    final energy = stats.energyKj;
    final controller = ref.read(sessionsProvider.notifier);

    final tiles = [
      StatTile(
        title: l10n.summaryDuration,
        value: formatDuration(session.duration),
      ),
      StatTile(title: l10n.summaryAverage, value: bpm(stats.averageBpm)),
      StatTile(title: l10n.summaryMax, value: bpm(stats.maxBpm)),
      StatTile(title: l10n.summaryMin, value: bpm(stats.minBpm)),
      if (rmssd != null)
        StatTile(title: l10n.summaryHrv, value: l10n.hrvValue(rmssd.round())),
      if (energy != null)
        StatTile(title: l10n.summaryEnergy, value: l10n.energyValue(energy)),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${l10n.summarySensor}: ${session.deviceName}',
                  style: theme.textTheme.titleMedium,
                ),
                if (session.simulated) Chip(label: Text(l10n.simulatedBadge)),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.maxWidth / 200).floor().clamp(
                  2,
                  6,
                );
                final width =
                    (constraints.maxWidth - (columns - 1) * 8) / columns;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tile in tiles)
                      SizedBox(width: width, child: tile),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 12),
                      child: Text(
                        l10n.wholeSessionChart,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    SizedBox(
                      height: 240,
                      child: HeartRateChart(
                        samples: session.samples,
                        maxHr: session.maxHr,
                        start: session.startedAt,
                        semanticLabel: l10n.chartSessionSemantics(
                          stats.averageBpm ?? 0,
                          stats.maxBpm ?? 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.timeInZonesTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      l10n.maxHrNote(session.maxHr),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    ZoneTimeBars(
                      timeInZones: stats.timeInZones,
                      maxHr: session.maxHr,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.tonalIcon(
                  key: const Key('export-csv'),
                  onPressed: () =>
                      _export(context, () => controller.exportCsv(session)),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: Text(l10n.exportCsv),
                ),
                MenuAnchor(
                  menuChildren: [
                    for (final sport in TcxSport.values)
                      MenuItemButton(
                        key: Key('export-tcx-${sport.name}'),
                        onPressed: () => _export(
                          context,
                          () => controller.exportTcx(session, sport),
                        ),
                        child: Text(switch (sport) {
                          TcxSport.running => l10n.tcxSportRunning,
                          TcxSport.biking => l10n.tcxSportBiking,
                          TcxSport.other => l10n.tcxSportOther,
                        }),
                      ),
                  ],
                  builder: (context, menu, _) => Tooltip(
                    message: l10n.exportTcxHint,
                    child: FilledButton.tonalIcon(
                      key: const Key('export-tcx'),
                      onPressed: () => menu.isOpen ? menu.close() : menu.open(),
                      icon: const Icon(Icons.directions_run),
                      label: Text(l10n.exportTcx),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

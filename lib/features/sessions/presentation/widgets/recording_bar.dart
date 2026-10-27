import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../monitor/presentation/monitor_controller.dart';
import '../live_stats.dart';
import '../recorder_controller.dart';
import '../session_detail_screen.dart';

/// Start and stop recording, with the running time and average while it
/// records.
class RecordingBar extends ConsumerWidget {
  const RecordingBar({super.key});

  Future<void> _stop(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await ref.read(recorderProvider.notifier).stop();
    switch (result) {
      case null:
        return;
      case RecordingSaved(:final session):
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.sessionSaved),
            persist: false,
            action: SnackBarAction(
              label: l10n.viewSession,
              onPressed: () => navigator.push(
                MaterialPageRoute<void>(
                  builder: (_) => SessionDetailScreen(sessionId: session.id),
                ),
              ),
            ),
          ),
        );
      case RecordingEmpty():
        messenger.showSnackBar(SnackBar(content: Text(l10n.nothingRecorded)));
      case RecordingStorageFull():
        messenger.showSnackBar(SnackBar(content: Text(l10n.storageFull)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final recording = ref.watch(recorderProvider);
    final stats = ref.watch(liveStatsProvider);
    final live = ref.watch(monitorProvider) is MonitorLive;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (recording) {
          RecorderIdle() => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                key: const Key('record'),
                onPressed: live
                    ? () => ref.read(recorderProvider.notifier).start()
                    : null,
                icon: const Icon(Icons.fiber_manual_record),
                label: Text(l10n.recordButton),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.recordingHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          RecorderRecording() => Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fiber_manual_record,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.recordingLabel(
                      formatDuration(stats?.duration ?? Duration.zero),
                    ),
                    key: const Key('recording-label'),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              if (stats?.averageBpm case final average?)
                Text(
                  '${l10n.summaryAverage} ${l10n.bpmValue(average)} · '
                  '${l10n.summaryMax} ${l10n.bpmValue(stats!.maxBpm!)}',
                ),
              FilledButton.icon(
                key: const Key('stop'),
                onPressed: () => _stop(context, ref),
                icon: const Icon(Icons.stop),
                label: Text(l10n.stopButton),
              ),
            ],
          ),
        },
      ),
    );
  }
}

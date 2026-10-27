import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../monitor/presentation/monitor_controller.dart';
import '../../monitor/presentation/zone_settings_controller.dart';
import '../domain/session_stats.dart';
import 'recorder_controller.dart';

/// Stats for the live view: the current recording, or everything since
/// connecting when not recording. Null when not connected.
final liveStatsProvider = Provider<SessionStats?>((ref) {
  final live = ref.watch(monitorProvider);
  if (live is! MonitorLive) return null;
  final recording = ref.watch(recorderProvider);
  final settingsMaxHr = ref.watch(zoneSettingsProvider).maxHr;
  final (from, maxHr) = switch (recording) {
    RecorderRecording(:final startedAt, :final maxHr) => (startedAt, maxHr),
    RecorderIdle() => (live.connectedAt, settingsMaxHr),
  };
  final samples = live.samples
      .where((sample) => !sample.time.isBefore(from))
      .toList(growable: false);
  return SessionStats.ofSamples(
    samples,
    maxHr: maxHr,
    duration: ref.read(clockProvider)().difference(from),
  );
});

/// Max HR the live zones use: frozen while recording, otherwise the settings.
final liveMaxHrProvider = Provider<int>((ref) {
  final recording = ref.watch(recorderProvider);
  return recording is RecorderRecording
      ? recording.maxHr
      : ref.watch(zoneSettingsProvider).maxHr;
});

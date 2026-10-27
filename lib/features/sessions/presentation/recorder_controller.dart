import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../monitor/presentation/monitor_controller.dart';
import '../../monitor/presentation/zone_settings_controller.dart';
import '../domain/recorded_session.dart';
import '../domain/session_repository.dart';
import 'sessions_controller.dart';

final recorderProvider = NotifierProvider<RecorderController, RecorderState>(
  RecorderController.new,
);

sealed class RecorderState {
  const RecorderState();
}

final class RecorderIdle extends RecorderState {
  const RecorderIdle();
}

final class RecorderRecording extends RecorderState {
  const RecorderRecording({required this.startedAt, required this.maxHr});

  final DateTime startedAt;

  /// Zones are fixed for the whole recording.
  final int maxHr;
}

/// What happened when a recording stopped.
sealed class RecordingResult {
  const RecordingResult();
}

final class RecordingSaved extends RecordingResult {
  const RecordingSaved(this.session);

  final RecordedSession session;
}

/// Stopped before any valid reading arrived, so nothing was saved.
final class RecordingEmpty extends RecordingResult {
  const RecordingEmpty();
}

final class RecordingStorageFull extends RecordingResult {
  const RecordingStorageFull();
}

/// Records the live readings into a session. If the sensor is disconnected
/// while recording, what was recorded so far is saved.
class RecorderController extends Notifier<RecorderState> {
  @override
  RecorderState build() {
    ref.listen(monitorProvider, (previous, next) {
      if (previous is MonitorLive && next is! MonitorLive) {
        unawaited(_finish(previous));
      }
    });
    return const RecorderIdle();
  }

  void start() {
    if (state is RecorderRecording ||
        ref.read(monitorProvider) is! MonitorLive) {
      return;
    }
    state = RecorderRecording(
      startedAt: ref.read(clockProvider)(),
      maxHr: ref.read(zoneSettingsProvider).maxHr,
    );
  }

  Future<RecordingResult?> stop() async {
    final live = ref.read(monitorProvider);
    if (live is! MonitorLive) return null;
    return _finish(live);
  }

  Future<RecordingResult?> _finish(MonitorLive live) async {
    final recording = state;
    if (recording is! RecorderRecording) return null;
    state = const RecorderIdle();
    final samples = live.samples
        .where((s) => !s.time.isBefore(recording.startedAt))
        .toList(growable: false);
    if (!samples.any((s) => s.isValid)) return const RecordingEmpty();
    final session = RecordedSession(
      id: recording.startedAt.microsecondsSinceEpoch.toString(),
      startedAt: recording.startedAt,
      endedAt: ref.read(clockProvider)(),
      deviceName: live.deviceName,
      simulated: live.simulated,
      maxHr: recording.maxHr,
      samples: samples,
    );
    try {
      await ref.read(sessionsProvider.notifier).add(session);
    } on SessionStorageException catch (error, stackTrace) {
      developer.log(
        'Recording not saved',
        name: 'heart_rate_web',
        error: error,
        stackTrace: stackTrace,
      );
      return const RecordingStorageFull();
    }
    return RecordingSaved(session);
  }
}

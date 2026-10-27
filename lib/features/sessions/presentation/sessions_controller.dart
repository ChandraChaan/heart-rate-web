import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/file_saver.dart';
import '../../../core/preferences.dart';
import '../data/browser_session_repository.dart';
import '../domain/csv_export.dart';
import '../domain/recorded_session.dart';
import '../domain/session_repository.dart';
import '../domain/session_stats.dart';
import '../domain/tcx_export.dart';

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => BrowserSessionRepository(ref.watch(sharedPreferencesProvider)),
);

final sessionsProvider =
    AsyncNotifierProvider<SessionsController, List<RecordedSession>>(
      SessionsController.new,
    );

/// One saved session by id, or null if it's gone.
final sessionProvider = Provider.family<RecordedSession?, String>((ref, id) {
  final sessions = ref.watch(sessionsProvider).value ?? const [];
  for (final session in sessions) {
    if (session.id == id) return session;
  }
  return null;
});

/// Summary of one saved session, computed once.
final sessionStatsProvider = Provider.family<SessionStats?, String>((ref, id) {
  final session = ref.watch(sessionProvider(id));
  return session == null ? null : SessionStats.of(session);
});

/// Saved sessions, newest first.
class SessionsController extends AsyncNotifier<List<RecordedSession>> {
  @override
  Future<List<RecordedSession>> build() =>
      ref.watch(sessionRepositoryProvider).loadAll();

  /// Throws a [SessionStorageException] if the browser storage is full.
  Future<void> add(RecordedSession session) async {
    await ref.read(sessionRepositoryProvider).save(session);
    if (!ref.mounted) return;
    final current = state.value ?? const [];
    state = AsyncData([session, ...current.where((s) => s.id != session.id)]);
  }

  Future<void> delete(String id) async {
    await ref.read(sessionRepositoryProvider).delete(id);
    if (!ref.mounted) return;
    final current = state.value ?? const [];
    state = AsyncData(current.where((s) => s.id != id).toList());
  }

  /// Downloads [session] as CSV.
  Future<void> exportCsv(RecordedSession session) => ref
      .read(fileSaverProvider)
      .save(
        fileName: exportFileName(session, 'csv'),
        mimeType: 'text/csv',
        contents: sessionToCsv(session),
      );

  /// Downloads [session] as TCX, for training apps.
  Future<void> exportTcx(RecordedSession session, TcxSport sport) => ref
      .read(fileSaverProvider)
      .save(
        fileName: exportFileName(session, 'tcx'),
        mimeType: 'application/vnd.garmin.tcx+xml',
        contents: sessionToTcx(session, sport: sport),
      );
}

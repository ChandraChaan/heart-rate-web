import 'recorded_session.dart';

/// Where recordings are kept: the browser's local storage in the app.
abstract interface class SessionRepository {
  /// Every saved session, newest first.
  ///
  /// Throws a [SessionStorageException] if the stored data can't be read.
  Future<List<RecordedSession>> loadAll();

  /// Throws a [SessionStorageException] if the browser storage is full.
  Future<void> save(RecordedSession session);

  Future<void> delete(String id);
}

enum SessionStorageException implements Exception { full, unreadable }

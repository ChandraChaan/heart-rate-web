import 'package:ble_gatt_parser/ble_gatt_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_web/features/monitor/domain/heart_rate_sample.dart';
import 'package:heart_rate_web/features/sessions/data/browser_session_repository.dart';
import 'package:heart_rate_web/features/sessions/domain/session_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fixtures.dart';

void main() {
  late BrowserSessionRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = BrowserSessionRepository(
      await SharedPreferences.getInstance(),
    );
  });

  test('round-trips every field of a session', () {
    final session = sessionOf([
      HeartRateSample(
        time: t0,
        bpm: 150,
        contact: SensorContact.detected,
        rrIntervalsMs: const [400.4, 401.5],
        energyKj: 12,
      ),
      HeartRateSample(
        time: t0.add(const Duration(milliseconds: 1250)),
        bpm: 0,
        contact: SensorContact.notDetected,
      ),
    ], simulated: true);
    expect(decodeSession(encodeSession(session)), session);
  });

  test('saves, lists newest first, and deletes', () async {
    final older = sessionOf(samplesOf([70, 71]), id: 'a');
    final newer = sessionOf(
      samplesOf([80, 81], start: t0.add(const Duration(days: 1))),
      id: 'b',
    );
    await repository.save(older);
    await repository.save(newer);
    expect((await repository.loadAll()).map((s) => s.id), ['b', 'a']);

    await repository.delete('b');
    expect((await repository.loadAll()).map((s) => s.id), ['a']);
  });

  test('saving the same id again replaces the session', () async {
    await repository.save(sessionOf(samplesOf([70]), id: 'a'));
    await repository.save(sessionOf(samplesOf([90, 91]), id: 'a'));
    final sessions = await repository.loadAll();
    expect(sessions, hasLength(1));
    expect(sessions.single.samples, hasLength(2));
  });

  test('skips a corrupt session but keeps the rest', () async {
    await repository.save(sessionOf(samplesOf([70]), id: 'good'));
    SharedPreferences.setMockInitialValues({
      'sessions.index': ['bad', 'good'],
      'sessions.bad': '{not json',
      'sessions.good': encodeSession(sessionOf(samplesOf([70]), id: 'good')),
    });
    repository = BrowserSessionRepository(
      await SharedPreferences.getInstance(),
    );
    expect((await repository.loadAll()).map((s) => s.id), ['good']);
  });

  test('reports unreadable storage when nothing can be read', () async {
    SharedPreferences.setMockInitialValues({
      'sessions.index': ['bad'],
      'sessions.bad': '{"v": 99}',
    });
    repository = BrowserSessionRepository(
      await SharedPreferences.getInstance(),
    );
    expect(repository.loadAll(), throwsA(SessionStorageException.unreadable));
  });
}

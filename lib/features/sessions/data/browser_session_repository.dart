import 'dart:convert';
import 'dart:developer' as developer;

import 'package:ble_gatt_parser/ble_gatt_parser.dart' show SensorContact;
import 'package:shared_preferences/shared_preferences.dart';

import '../../monitor/domain/heart_rate_sample.dart';
import '../domain/recorded_session.dart';
import '../domain/session_repository.dart';

/// Keeps sessions in the browser's local storage, one key per session plus
/// an index. Samples are stored column by column to stay small: an hour at
/// one reading a second is roughly 60 KB.
final class BrowserSessionRepository implements SessionRepository {
  const BrowserSessionRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _indexKey = 'sessions.index';
  static const _formatVersion = 1;

  static String _key(String id) => 'sessions.$id';

  List<String> get _ids => _preferences.getStringList(_indexKey) ?? const [];

  @override
  Future<List<RecordedSession>> loadAll() async {
    final sessions = <RecordedSession>[];
    for (final id in _ids) {
      final json = _preferences.getString(_key(id));
      if (json == null) continue;
      try {
        sessions.add(decodeSession(json));
      } on Object catch (error, stackTrace) {
        developer.log(
          'Skipping unreadable session $id',
          name: 'heart_rate_web',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    if (sessions.isEmpty && _ids.isNotEmpty) {
      throw SessionStorageException.unreadable;
    }
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions;
  }

  @override
  Future<void> save(RecordedSession session) async {
    try {
      final saved = await _preferences.setString(
        _key(session.id),
        encodeSession(session),
      );
      if (!saved) throw SessionStorageException.full;
      await _preferences.setStringList(_indexKey, [
        ..._ids.where((id) => id != session.id),
        session.id,
      ]);
    } on SessionStorageException {
      rethrow;
    } on Object catch (error, stackTrace) {
      // Browsers throw QuotaExceededError when local storage is full.
      developer.log(
        'Saving session failed',
        name: 'heart_rate_web',
        error: error,
        stackTrace: stackTrace,
      );
      await _preferences.remove(_key(session.id));
      throw SessionStorageException.full;
    }
  }

  @override
  Future<void> delete(String id) async {
    await _preferences.setStringList(
      _indexKey,
      _ids.where((existing) => existing != id).toList(),
    );
    await _preferences.remove(_key(id));
  }
}

String encodeSession(RecordedSession session) {
  final start = session.startedAt.toUtc();
  final samples = session.samples;
  return jsonEncode({
    'v': BrowserSessionRepository._formatVersion,
    'id': session.id,
    'start': start.toIso8601String(),
    'end': session.endedAt.toUtc().toIso8601String(),
    'device': session.deviceName,
    'simulated': session.simulated,
    'maxHr': session.maxHr,
    't': [for (final s in samples) s.time.difference(start).inMilliseconds],
    'bpm': [for (final s in samples) s.bpm],
    'contact': [for (final s in samples) s.contact.index],
    'rr': [
      for (final s in samples)
        [for (final rr in s.rrIntervalsMs) (rr * 10).round() / 10],
    ],
    'energy': [for (final s in samples) s.energyKj],
  });
}

RecordedSession decodeSession(String json) {
  final map = jsonDecode(json) as Map<String, Object?>;
  if (map['v'] != BrowserSessionRepository._formatVersion) {
    throw FormatException('Unknown session format ${map['v']}');
  }
  final start = DateTime.parse(map['start']! as String).toUtc();
  final offsets = (map['t']! as List<Object?>).cast<int>();
  final bpm = (map['bpm']! as List<Object?>).cast<int>();
  final contact = (map['contact']! as List<Object?>).cast<int>();
  final rr = (map['rr']! as List<Object?>).cast<List<Object?>>();
  final energy = (map['energy']! as List<Object?>).cast<int?>();
  return RecordedSession(
    id: map['id']! as String,
    startedAt: start,
    endedAt: DateTime.parse(map['end']! as String).toUtc(),
    deviceName: map['device']! as String,
    simulated: map['simulated']! as bool,
    maxHr: map['maxHr']! as int,
    samples: [
      for (var i = 0; i < offsets.length; i++)
        HeartRateSample(
          time: start.add(Duration(milliseconds: offsets[i])),
          bpm: bpm[i],
          contact: SensorContact.values[contact[i]],
          rrIntervalsMs: [for (final v in rr[i]) (v! as num).toDouble()],
          energyKj: energy[i],
        ),
    ],
  );
}

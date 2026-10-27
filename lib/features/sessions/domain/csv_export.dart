import '../../monitor/domain/heart_rate_zones.dart';
import 'recorded_session.dart';

/// One row per reading, for spreadsheets and scripts.
///
/// Columns: UTC time, seconds since the start, bpm, zone (0 is below zone
/// 1), sensor contact, RR-intervals in ms separated by spaces, and energy in
/// kJ. Lines end in CRLF as RFC 4180 asks.
String sessionToCsv(RecordedSession session) {
  final zones = HeartRateZones(session.maxHr);
  final buffer = StringBuffer(
    'time_utc,elapsed_s,bpm,zone,sensor_contact,rr_intervals_ms,energy_kj\r\n',
  );
  for (final sample in session.samples) {
    final elapsed =
        sample.time.difference(session.startedAt).inMilliseconds / 1000;
    buffer
      ..write(sample.time.toUtc().toIso8601String())
      ..write(',')
      ..write(elapsed.toStringAsFixed(3))
      ..write(',')
      ..write(sample.bpm)
      ..write(',')
      ..write(sample.isValid ? zones.zoneOf(sample.bpm).number : '')
      ..write(',')
      ..write(sample.contact.name)
      ..write(',')
      ..write(sample.rrIntervalsMs.map((rr) => rr.toStringAsFixed(1)).join(' '))
      ..write(',')
      ..write(sample.energyKj ?? '')
      ..write('\r\n');
  }
  return buffer.toString();
}

/// `heart-rate-2026-10-27-0930.csv`, from the start time in UTC.
String exportFileName(RecordedSession session, String extension) {
  final t = session.startedAt.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return 'heart-rate-${t.year}-${two(t.month)}-${two(t.day)}-'
      '${two(t.hour)}${two(t.minute)}.$extension';
}

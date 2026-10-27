import 'package:ble_gatt_parser/ble_gatt_parser.dart';

/// One Heart Rate Measurement notification, stamped with the time it arrived.
final class HeartRateSample {
  const HeartRateSample({
    required this.time,
    required this.bpm,
    this.rrIntervalsMs = const [],
    this.contact = SensorContact.notSupported,
    this.energyKj,
  });

  /// Builds a sample from a parsed measurement received at [time] (UTC).
  factory HeartRateSample.fromMeasurement(
    DateTime time,
    HeartRateMeasurement measurement,
  ) => HeartRateSample(
    time: time.toUtc(),
    bpm: measurement.bpm,
    rrIntervalsMs: measurement.rrIntervalsMs,
    contact: measurement.sensorContact,
    energyKj: measurement.energyExpendedKj,
  );

  /// When the notification arrived, in UTC.
  final DateTime time;
  final int bpm;

  /// Beat-to-beat intervals in milliseconds. Empty when the sensor doesn't
  /// send them.
  final List<double> rrIntervalsMs;
  final SensorContact contact;

  /// Energy expended since the sensor was reset, in kilojoules.
  final int? energyKj;

  /// Whether the reading can be trusted: straps send 0 bpm, or a stale value,
  /// when they lose skin contact.
  bool get isValid => bpm > 0 && contact != SensorContact.notDetected;

  @override
  bool operator ==(Object other) =>
      other is HeartRateSample &&
      other.time == time &&
      other.bpm == bpm &&
      other.contact == contact &&
      other.energyKj == energyKj &&
      _listEquals(other.rrIntervalsMs, rrIntervalsMs);

  @override
  int get hashCode =>
      Object.hash(time, bpm, contact, energyKj, Object.hashAll(rrIntervalsMs));

  @override
  String toString() => 'HeartRateSample($time, $bpm bpm)';
}

bool _listEquals(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

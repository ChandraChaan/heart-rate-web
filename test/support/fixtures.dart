import 'package:ble_gatt_parser/ble_gatt_parser.dart';
import 'package:heart_rate_web/features/monitor/domain/heart_rate_sample.dart';
import 'package:heart_rate_web/features/sessions/domain/recorded_session.dart';

final t0 = DateTime.utc(2026, 10, 27, 9, 30);

/// One sample a second from [t0], with the given heart rates.
List<HeartRateSample> samplesOf(
  List<int> bpm, {
  DateTime? start,
  List<double> Function(int bpm)? rr,
}) => [
  for (var i = 0; i < bpm.length; i++)
    HeartRateSample(
      time: (start ?? t0).add(Duration(seconds: i)),
      bpm: bpm[i],
      contact: SensorContact.detected,
      rrIntervalsMs: rr?.call(bpm[i]) ?? const [],
    ),
];

RecordedSession sessionOf(
  List<HeartRateSample> samples, {
  String id = 'test',
  int maxHr = 200,
  bool simulated = false,
}) => RecordedSession(
  id: id,
  startedAt: samples.isEmpty ? t0 : samples.first.time,
  endedAt: samples.isEmpty
      ? t0
      : samples.last.time.add(const Duration(seconds: 1)),
  deviceName: 'Polar H10 <Test & Co>',
  simulated: simulated,
  maxHr: maxHr,
  samples: samples,
);

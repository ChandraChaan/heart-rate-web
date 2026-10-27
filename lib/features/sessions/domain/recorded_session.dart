import '../../monitor/domain/heart_rate_sample.dart';

/// A recording, as saved in the browser.
final class RecordedSession {
  const RecordedSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.deviceName,
    required this.simulated,
    required this.maxHr,
    required this.samples,
  });

  final String id;

  /// Start and end, in UTC.
  final DateTime startedAt;
  final DateTime endedAt;
  final String deviceName;

  /// Recorded in demo mode.
  final bool simulated;

  /// Max HR the zones were calculated from when it was recorded.
  final int maxHr;
  final List<HeartRateSample> samples;

  Duration get duration => endedAt.difference(startedAt);

  @override
  bool operator ==(Object other) =>
      other is RecordedSession &&
      other.id == id &&
      other.startedAt == startedAt &&
      other.endedAt == endedAt &&
      other.deviceName == deviceName &&
      other.simulated == simulated &&
      other.maxHr == maxHr &&
      _samplesEqual(other.samples, samples);

  @override
  int get hashCode => Object.hash(id, startedAt, endedAt, samples.length);
}

bool _samplesEqual(List<HeartRateSample> a, List<HeartRateSample> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

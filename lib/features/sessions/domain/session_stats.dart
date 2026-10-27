import '../../monitor/domain/heart_rate_sample.dart';
import '../../monitor/domain/heart_rate_zones.dart';
import '../../monitor/domain/hrv.dart';
import 'recorded_session.dart';

/// Summary numbers for a recording, or for the live samples so far.
final class SessionStats {
  const SessionStats({
    required this.duration,
    required this.timeInZones,
    this.averageBpm,
    this.minBpm,
    this.maxBpm,
    this.rmssdMs,
    this.energyKj,
  });

  factory SessionStats.of(RecordedSession session) => SessionStats.ofSamples(
    session.samples,
    maxHr: session.maxHr,
    duration: session.duration,
  );

  factory SessionStats.ofSamples(
    List<HeartRateSample> samples, {
    required int maxHr,
    required Duration duration,
  }) {
    final valid = samples.where((sample) => sample.isValid).toList();
    int? min, max;
    var sum = 0;
    for (final sample in valid) {
      sum += sample.bpm;
      if (min == null || sample.bpm < min) min = sample.bpm;
      if (max == null || sample.bpm > max) max = sample.bpm;
    }
    final energy = samples
        .map((sample) => sample.energyKj)
        .whereType<int>()
        .toList();
    return SessionStats(
      duration: duration,
      timeInZones: HeartRateZones(maxHr).timeInZones(samples),
      averageBpm: valid.isEmpty ? null : (sum / valid.length).round(),
      minBpm: min,
      maxBpm: max,
      rmssdMs: Hrv.rmssdOfSamples(samples),
      // Straps count energy up from when they were reset, so the recording's
      // share is the difference. A reset mid-recording makes it go down.
      energyKj: energy.length < 2 || energy.last < energy.first
          ? null
          : energy.last - energy.first,
    );
  }

  final Duration duration;
  final Map<HeartRateZone, Duration> timeInZones;
  final int? averageBpm;
  final int? minBpm;
  final int? maxBpm;

  /// RMSSD over the whole recording, if the sensor sent RR-intervals.
  final double? rmssdMs;
  final int? energyKj;

  bool get hasReadings => averageBpm != null;
}

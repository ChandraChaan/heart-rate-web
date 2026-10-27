import 'dart:math' as math;

import 'heart_rate_sample.dart';

/// Heart-rate variability from RR-intervals.
abstract final class Hrv {
  /// Fewest usable successive differences before RMSSD is reported.
  static const minDifferences = 10;

  /// RR-intervals outside this range (30–200 bpm) are treated as artefacts.
  static const minRrMs = 300.0;
  static const maxRrMs = 2000.0;

  /// A beat that differs from the one before by more than this share is
  /// likely a missed or extra beat, so the pair is skipped.
  static const maxRelativeChange = 0.2;

  /// RMSSD, the root mean square of successive RR differences, in
  /// milliseconds. Returns null if there are too few clean intervals.
  ///
  /// [rrIntervalsMs] must be in the order the beats happened.
  static double? rmssd(List<double> rrIntervalsMs) {
    var sumOfSquares = 0.0;
    var count = 0;
    double? previous;
    for (final rr in rrIntervalsMs) {
      if (rr < minRrMs || rr > maxRrMs) {
        previous = null;
        continue;
      }
      if (previous != null) {
        final difference = rr - previous;
        if (difference.abs() <= previous * maxRelativeChange) {
          sumOfSquares += difference * difference;
          count++;
        }
      }
      previous = rr;
    }
    if (count < minDifferences) return null;
    return math.sqrt(sumOfSquares / count);
  }

  /// RMSSD over the RR-intervals of valid samples received in the [window]
  /// up to [now]. Intervals from either side of a lost-contact sample are not
  /// paired up.
  static double? rmssdOfSamples(
    List<HeartRateSample> samples, {
    DateTime? now,
    Duration window = const Duration(seconds: 60),
  }) {
    // Walk back from the newest sample, so live updates stay cheap however
    // long the connection has been open.
    var first = 0;
    if (now != null) {
      final from = now.subtract(window);
      first = samples.length;
      while (first > 0 && !samples[first - 1].time.isBefore(from)) {
        first--;
      }
    }
    final intervals = <double>[];
    for (final sample in samples.skip(first)) {
      if (!sample.isValid) {
        // A 0 between runs breaks the chain, see [rmssd].
        intervals.add(0);
        continue;
      }
      intervals.addAll(sample.rrIntervalsMs);
    }
    return rmssd(intervals);
  }
}

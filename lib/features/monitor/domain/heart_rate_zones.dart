import 'heart_rate_sample.dart';

/// Training zones as a share of maximum heart rate, the five-zone model used
/// by most straps and training apps. [rest] is everything below zone 1.
enum HeartRateZone {
  rest(0, 0.5),
  zone1(0.5, 0.6),
  zone2(0.6, 0.7),
  zone3(0.7, 0.8),
  zone4(0.8, 0.9),
  zone5(0.9, double.infinity);

  const HeartRateZone(this.lowerFraction, this.upperFraction);

  /// Lower bound as a fraction of max HR, inclusive.
  final double lowerFraction;

  /// Upper bound as a fraction of max HR, exclusive.
  final double upperFraction;

  /// 1–5, or 0 for [rest].
  int get number => index;
}

/// What the zones are calculated from: a measured max HR if the user knows
/// it, otherwise the age estimate.
final class ZoneSettings {
  const ZoneSettings({this.age = defaultAge, this.measuredMaxHr});

  static const defaultAge = 35;
  static const minAge = 10;
  static const maxAge = 100;
  static const minMaxHr = 100;
  static const maxMaxHr = 230;

  final int age;

  /// Max HR from a lab or field test. Overrides the age estimate.
  final int? measuredMaxHr;

  /// Max HR in bpm. Without a measured value it uses the common 220 − age
  /// estimate, which can be off by 10 bpm or more either way.
  int get maxHr => measuredMaxHr ?? 220 - age;

  ZoneSettings copyWith({int? age, int? Function()? measuredMaxHr}) =>
      ZoneSettings(
        age: age ?? this.age,
        measuredMaxHr: measuredMaxHr != null
            ? measuredMaxHr()
            : this.measuredMaxHr,
      );

  @override
  bool operator ==(Object other) =>
      other is ZoneSettings &&
      other.age == age &&
      other.measuredMaxHr == measuredMaxHr;

  @override
  int get hashCode => Object.hash(age, measuredMaxHr);
}

/// Maps heart rates to zones for one max HR.
final class HeartRateZones {
  const HeartRateZones(this.maxHr) : assert(maxHr > 0);

  final int maxHr;

  HeartRateZone zoneOf(int bpm) {
    final fraction = bpm / maxHr;
    for (final zone in HeartRateZone.values.reversed) {
      if (fraction >= zone.lowerFraction) return zone;
    }
    return HeartRateZone.rest;
  }

  /// Lowest bpm in [zone], rounded to the nearest beat.
  int lowerBpm(HeartRateZone zone) => (zone.lowerFraction * maxHr).round();

  /// Highest bpm in [zone], or null for zone 5, which has no top.
  int? upperBpm(HeartRateZone zone) => zone == HeartRateZone.zone5
      ? null
      : lowerBpm(HeartRateZone.values[zone.index + 1]) - 1;

  /// Time spent in each zone. Only valid samples count (see
  /// [HeartRateSample.isValid]). Each sample covers the time until the next
  /// one; a gap longer than [maxGap], such as a dropped connection, counts
  /// as [typicalInterval] instead.
  Map<HeartRateZone, Duration> timeInZones(
    List<HeartRateSample> samples, {
    Duration maxGap = const Duration(seconds: 5),
    Duration typicalInterval = const Duration(seconds: 1),
  }) {
    final result = {
      for (final zone in HeartRateZone.values) zone: Duration.zero,
    };
    for (var i = 0; i < samples.length; i++) {
      final sample = samples[i];
      if (!sample.isValid) continue;
      var covered = typicalInterval;
      if (i + 1 < samples.length) {
        final gap = samples[i + 1].time.difference(sample.time);
        if (gap >= Duration.zero && gap <= maxGap) covered = gap;
      }
      final zone = zoneOf(sample.bpm);
      result[zone] = result[zone]! + covered;
    }
    return result;
  }
}

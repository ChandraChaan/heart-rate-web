import 'package:ble_gatt_parser/ble_gatt_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_web/features/monitor/domain/heart_rate_sample.dart';
import 'package:heart_rate_web/features/monitor/domain/heart_rate_zones.dart';
import 'package:heart_rate_web/features/sessions/domain/session_stats.dart';

import '../../support/fixtures.dart';

void main() {
  test('summarises average, min, max, duration and zones', () {
    final session = sessionOf(samplesOf([100, 120, 140, 160, 180]));
    final stats = SessionStats.of(session);
    expect(stats.averageBpm, 140);
    expect(stats.minBpm, 100);
    expect(stats.maxBpm, 180);
    expect(stats.duration, const Duration(seconds: 5));
    expect(stats.hasReadings, isTrue);
    for (final zone in HeartRateZone.values.skip(1)) {
      expect(
        stats.timeInZones[zone],
        const Duration(seconds: 1),
        reason: '$zone',
      );
    }
  });

  test('rounds the average to the nearest beat', () {
    final stats = SessionStats.of(sessionOf(samplesOf([100, 101])));
    expect(stats.averageBpm, 101); // 100.5
  });

  test('ignores readings without skin contact', () {
    final samples = [
      ...samplesOf([150, 152]),
      HeartRateSample(
        time: t0.add(const Duration(seconds: 2)),
        bpm: 40,
        contact: SensorContact.notDetected,
      ),
    ];
    final stats = SessionStats.of(sessionOf(samples));
    expect(stats.minBpm, 150);
    expect(stats.averageBpm, 151);
  });

  test('has no readings when every sample is invalid', () {
    final samples = [HeartRateSample(time: t0, bpm: 0)];
    final stats = SessionStats.of(sessionOf(samples));
    expect(stats.hasReadings, isFalse);
    expect(stats.averageBpm, isNull);
    expect(stats.maxBpm, isNull);
  });

  test('reports RMSSD when the strap sent RR-intervals', () {
    final stats = SessionStats.of(
      sessionOf(samplesOf(List.filled(10, 75), rr: (_) => [800, 820])),
    );
    expect(stats.rmssdMs, closeTo(20, 1e-9));
    expect(
      SessionStats.of(sessionOf(samplesOf(List.filled(10, 75)))).rmssdMs,
      isNull,
    );
  });

  test('energy is what the strap counted during the recording', () {
    HeartRateSample at(int second, int? energy) => HeartRateSample(
      time: t0.add(Duration(seconds: second)),
      bpm: 120,
      energyKj: energy,
    );
    expect(
      SessionStats.of(
        sessionOf([at(0, 400), at(1, null), at(2, 412)]),
      ).energyKj,
      12,
    );
    // The strap was reset mid-recording: no trustworthy total.
    expect(SessionStats.of(sessionOf([at(0, 400), at(1, 3)])).energyKj, isNull);
    expect(SessionStats.of(sessionOf([at(0, null)])).energyKj, isNull);
  });
}

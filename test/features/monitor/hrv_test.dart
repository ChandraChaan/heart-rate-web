import 'dart:math' as math;

import 'package:ble_gatt_parser/ble_gatt_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_web/features/monitor/domain/heart_rate_sample.dart';
import 'package:heart_rate_web/features/monitor/domain/hrv.dart';

import '../../support/fixtures.dart';

void main() {
  group('Hrv.rmssd', () {
    test('matches a hand-worked example', () {
      // Differences 20, -20, 20, ... so RMSSD is exactly 20.
      final rr = [for (var i = 0; i < 12; i++) i.isEven ? 800.0 : 820.0];
      expect(Hrv.rmssd(rr), closeTo(20, 1e-9));
    });

    test('computes the root mean square of successive differences', () {
      final rr = <double>[
        1000,
        1010,
        990,
        1000,
        1030,
        1000,
        1020,
        1000,
        990,
        1010,
        1000,
      ];
      // Differences: 10, -20, 10, 30, -30, 20, -20, -10, 20, -10.
      const squares = 100 + 400 + 100 + 900 + 900 + 400 + 400 + 100 + 400 + 100;
      expect(Hrv.rmssd(rr), closeTo(math.sqrt(squares / 10), 1e-9));
    });

    test('is zero for a perfectly steady rhythm', () {
      expect(Hrv.rmssd(List.filled(20, 750)), 0);
    });

    test('needs at least ten differences', () {
      expect(Hrv.rmssd(List.filled(10, 800)), isNull);
      expect(Hrv.rmssd(List.filled(11, 800)), 0);
      expect(Hrv.rmssd(const []), isNull);
    });

    test('drops implausible intervals and the pairs around them', () {
      final clean = [for (var i = 0; i < 12; i++) i.isEven ? 800.0 : 820.0];
      final noisy = [...clean.take(6), 150.0, 3000.0, ...clean.skip(6)];
      // Only the pair that straddled the artefacts is lost.
      expect(Hrv.rmssd(noisy), closeTo(20, 1e-9));
    });

    test('skips pairs that differ by more than 20%, like a missed beat', () {
      final rr = <double>[
        for (var i = 0; i < 12; i++) i.isEven ? 800 : 820,
        1640, // Missed beat: two intervals counted as one.
        820,
      ];
      expect(Hrv.rmssd(rr), closeTo(20, 1e-9));
    });
  });

  group('Hrv.rmssdOfSamples', () {
    test('uses only the last minute', () {
      final old = samplesOf(
        List.filled(30, 60),
        rr: (_) => [700, 900],
      ); // Wild swings an hour ago.
      final recent = samplesOf(
        List.filled(30, 75),
        start: t0.add(const Duration(hours: 1)),
        rr: (_) => [800, 820],
      );
      final all = [...old, ...recent];
      expect(Hrv.rmssdOfSamples(all, now: recent.last.time), closeTo(20, 1e-9));
    });

    test('does not pair intervals across lost contact', () {
      final before = samplesOf(List.filled(6, 75), rr: (_) => [800, 820]);
      final gap = HeartRateSample(
        time: before.last.time.add(const Duration(seconds: 1)),
        bpm: 0,
        contact: SensorContact.notDetected,
      );
      final after = samplesOf(
        List.filled(6, 75),
        start: gap.time.add(const Duration(seconds: 1)),
        rr: (_) => [900, 920],
      );
      // Pairing 820 before the gap with 900 after it would raise RMSSD.
      expect(Hrv.rmssdOfSamples([...before, gap, ...after]), closeTo(20, 1e-9));
      expect(Hrv.rmssdOfSamples([...before, ...after]), greaterThan(20));
    });

    test('is null when the strap sends no RR-intervals', () {
      expect(Hrv.rmssdOfSamples(samplesOf(List.filled(120, 70))), isNull);
    });
  });
}

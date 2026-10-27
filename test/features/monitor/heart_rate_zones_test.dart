import 'package:ble_gatt_parser/ble_gatt_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_web/features/monitor/domain/heart_rate_sample.dart';
import 'package:heart_rate_web/features/monitor/domain/heart_rate_zones.dart';

import '../../support/fixtures.dart';

void main() {
  group('ZoneSettings', () {
    test('estimates max HR as 220 minus age', () {
      expect(const ZoneSettings(age: 40).maxHr, 180);
    });

    test('a measured max HR wins over the estimate', () {
      expect(const ZoneSettings(age: 40, measuredMaxHr: 192).maxHr, 192);
    });

    test('copyWith can clear the measured max HR', () {
      const settings = ZoneSettings(age: 40, measuredMaxHr: 192);
      expect(settings.copyWith(measuredMaxHr: () => null).maxHr, 180);
      expect(
        settings.copyWith(age: 30),
        const ZoneSettings(age: 30, measuredMaxHr: 192),
      );
    });
  });

  group('HeartRateZones', () {
    const zones = HeartRateZones(200);

    test('maps heart rates to zones at the boundaries', () {
      expect(zones.zoneOf(0), HeartRateZone.rest);
      expect(zones.zoneOf(99), HeartRateZone.rest);
      expect(zones.zoneOf(100), HeartRateZone.zone1);
      expect(zones.zoneOf(119), HeartRateZone.zone1);
      expect(zones.zoneOf(120), HeartRateZone.zone2);
      expect(zones.zoneOf(140), HeartRateZone.zone3);
      expect(zones.zoneOf(160), HeartRateZone.zone4);
      expect(zones.zoneOf(179), HeartRateZone.zone4);
      expect(zones.zoneOf(180), HeartRateZone.zone5);
      expect(zones.zoneOf(230), HeartRateZone.zone5);
    });

    test('gives bpm ranges that join up without gaps', () {
      expect(zones.lowerBpm(HeartRateZone.zone1), 100);
      expect(zones.upperBpm(HeartRateZone.rest), 99);
      expect(zones.upperBpm(HeartRateZone.zone1), 119);
      expect(zones.lowerBpm(HeartRateZone.zone5), 180);
      expect(zones.upperBpm(HeartRateZone.zone5), isNull);
      for (final zone in HeartRateZone.values.take(5)) {
        final next = HeartRateZone.values[zone.index + 1];
        expect(zones.upperBpm(zone)! + 1, zones.lowerBpm(next));
      }
    });

    test('rounds bounds for max HRs that are not multiples of ten', () {
      const odd = HeartRateZones(187);
      expect(odd.lowerBpm(HeartRateZone.zone3), 131); // 130.9
      expect(odd.zoneOf(131), HeartRateZone.zone3);
    });

    test('adds up time in each zone from one-second samples', () {
      final time = zones.timeInZones(samplesOf([90, 110, 110, 150, 185]));
      expect(time[HeartRateZone.rest], const Duration(seconds: 1));
      expect(time[HeartRateZone.zone1], const Duration(seconds: 2));
      expect(time[HeartRateZone.zone2], Duration.zero);
      expect(time[HeartRateZone.zone3], const Duration(seconds: 1));
      expect(time[HeartRateZone.zone5], const Duration(seconds: 1));
    });

    test('uses the real spacing between samples', () {
      final samples = [
        HeartRateSample(time: t0, bpm: 150),
        HeartRateSample(time: t0.add(const Duration(seconds: 3)), bpm: 150),
      ];
      expect(
        zones.timeInZones(samples)[HeartRateZone.zone3],
        const Duration(seconds: 4),
      );
    });

    test('does not count a dropped connection as time in a zone', () {
      final samples = [
        HeartRateSample(time: t0, bpm: 150),
        HeartRateSample(time: t0.add(const Duration(minutes: 2)), bpm: 150),
      ];
      expect(
        zones.timeInZones(samples)[HeartRateZone.zone3],
        const Duration(seconds: 2),
      );
    });

    test('skips readings without skin contact', () {
      final samples = [
        HeartRateSample(time: t0, bpm: 150, contact: SensorContact.detected),
        HeartRateSample(
          time: t0.add(const Duration(seconds: 1)),
          bpm: 150,
          contact: SensorContact.notDetected,
        ),
        HeartRateSample(time: t0.add(const Duration(seconds: 2)), bpm: 0),
      ];
      final total = zones
          .timeInZones(samples)
          .values
          .fold(Duration.zero, (a, b) => a + b);
      expect(total, const Duration(seconds: 1));
    });
  });
}

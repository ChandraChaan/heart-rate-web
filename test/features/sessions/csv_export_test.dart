import 'package:ble_gatt_parser/ble_gatt_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_web/features/monitor/domain/heart_rate_sample.dart';
import 'package:heart_rate_web/features/sessions/domain/csv_export.dart';

import '../../support/fixtures.dart';

void main() {
  test('writes a header and one row per sample', () {
    final session = sessionOf([
      HeartRateSample(
        time: t0,
        bpm: 150,
        contact: SensorContact.detected,
        rrIntervalsMs: const [400, 401.5],
        energyKj: 12,
      ),
      HeartRateSample(
        time: t0.add(const Duration(milliseconds: 1250)),
        bpm: 0,
        contact: SensorContact.notDetected,
      ),
    ]);
    final lines = sessionToCsv(session).split('\r\n');
    expect(lines, [
      'time_utc,elapsed_s,bpm,zone,sensor_contact,rr_intervals_ms,energy_kj',
      '2026-10-27T09:30:00.000Z,0.000,150,3,detected,400.0 401.5,12',
      '2026-10-27T09:30:01.250Z,1.250,0,,notDetected,,',
      '',
    ]);
  });

  test('every row has the same number of columns', () {
    final csv = sessionToCsv(
      sessionOf(samplesOf([60, 120, 190], rr: (bpm) => [60000 / bpm])),
    );
    final rows = csv.trim().split('\r\n');
    expect(rows, hasLength(4));
    for (final row in rows) {
      expect(row.split(','), hasLength(7), reason: row);
    }
  });

  test('names files after the start time', () {
    expect(
      exportFileName(sessionOf(samplesOf([70])), 'csv'),
      'heart-rate-2026-10-27-0930.csv',
    );
  });
}

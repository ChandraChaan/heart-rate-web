import 'package:ble_gatt_parser/ble_gatt_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_web/features/monitor/data/simulated_heart_rate.dart';
import 'package:heart_rate_web/features/monitor/domain/heart_rate_link.dart';

void main() {
  test('sends spec-correct Heart Rate Measurements', () async {
    final link =
        await const SimulatedHeartRateConnector(
              tickInterval: Duration.zero,
            ).connect()
            as SimulatedHeartRateLink;
    final received = <HeartRateMeasurement>[];
    final subscription = link
        .notifications(HeartRateUuids.heartRateMeasurement)
        .listen(
          (bytes) => received.add(
            GattParser.parse(HeartRateUuids.heartRateMeasurement, bytes)
                as HeartRateMeasurement,
          ),
        );
    for (var i = 0; i < 30; i++) {
      link.tick();
    }
    await subscription.cancel();

    expect(received, hasLength(30));
    for (final measurement in received) {
      expect(measurement.bpm, inInclusiveRange(65, 185));
      expect(measurement.sensorContact, SensorContact.detected);
      expect(measurement.rrIntervalsMs, hasLength(1));
    }
    await link.disconnect();
  });

  test('reads battery and body location, and nothing else', () async {
    final link = await const SimulatedHeartRateConnector(
      tickInterval: Duration.zero,
    ).connect();
    expect(
      GattParser.parse(
        HeartRateUuids.batteryLevel,
        (await link.read(HeartRateUuids.batteryLevel))!,
      ),
      isA<BatteryLevel>().having((b) => b.percent, 'percent', 82),
    );
    expect(await link.read(HeartRateUuids.bodySensorLocation), [1]);
    expect(await link.read(0x2A5B), isNull);
    await link.disconnect();
  });

  test('drops and comes back like a real strap', () async {
    final link =
        await const SimulatedHeartRateConnector(
              tickInterval: Duration.zero,
            ).connect()
            as SimulatedHeartRateLink;
    final changes = <bool>[];
    final subscription = link.connectionChanges.listen(changes.add);
    link.dropConnection();
    await link.reconnect();
    expect(changes, [false, true]);
    await subscription.cancel();
    await link.disconnect();
  });
}

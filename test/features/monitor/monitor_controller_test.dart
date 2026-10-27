import 'package:ble_gatt_parser/ble_gatt_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_web/core/clock.dart';
import 'package:heart_rate_web/core/preferences.dart';
import 'package:heart_rate_web/features/monitor/domain/heart_rate_link.dart';
import 'package:heart_rate_web/features/monitor/presentation/monitor_controller.dart';
import 'package:heart_rate_web/features/sessions/presentation/recorder_controller.dart';
import 'package:heart_rate_web/features/sessions/presentation/sessions_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fakes.dart';
import '../../support/fixtures.dart';

void main() {
  late FakeConnector bluetooth;
  late ManualDemoConnector demo;
  late DateTime now;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    bluetooth = FakeConnector();
    demo = ManualDemoConnector();
    now = t0;
    container = ProviderContainer.test(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        bluetoothConnectorProvider.overrideWithValue(bluetooth),
        demoConnectorProvider.overrideWithValue(demo),
        clockProvider.overrideWithValue(() => now),
      ],
      retry: (_, _) => null,
    );
  });

  MonitorController monitor() => container.read(monitorProvider.notifier);
  MonitorLive live() => container.read(monitorProvider) as MonitorLive;

  void advance([int seconds = 1]) => now = now.add(Duration(seconds: seconds));

  test('starts idle', () {
    expect(container.read(monitorProvider), isA<MonitorIdle>());
  });

  test('connects and parses measurements, battery and location', () async {
    await monitor().connect();
    expect(live().deviceName, 'Polar H10 1234');
    expect(live().simulated, isFalse);
    expect(live().batteryPercent, 64);
    expect(live().location, SensorLocation.chest);

    bluetooth.strap.sendHeartRate(72, rr: [833], contact: true);
    expect(live().latest!.bpm, 72);
    expect(live().latest!.rrIntervalsMs.single, closeTo(833, 1));
    expect(live().latest!.time, t0);
    expect(live().sendsRrIntervals, isTrue);

    bluetooth.strap.sendBattery(12);
    expect(live().batteryPercent, 12);
  });

  test('ignores malformed notifications', () async {
    await monitor().connect();
    // Flags promise a 16-bit heart rate that never comes.
    bluetooth.strap.sendRaw(HeartRateUuids.heartRateMeasurement, [0x01, 0x50]);
    bluetooth.strap.sendRaw(HeartRateUuids.batteryLevel, []);
    bluetooth.strap.sendHeartRate(80);
    expect(live().samples, hasLength(1));
  });

  test('reports a failed connection and can try again', () async {
    bluetooth.failure = BluetoothFailure.permissionDenied;
    await monitor().connect();
    expect(
      container.read(monitorProvider),
      isA<MonitorIdle>().having(
        (s) => s.failure,
        'failure',
        BluetoothFailure.permissionDenied,
      ),
    );

    bluetooth.failure = null;
    await monitor().connect();
    expect(container.read(monitorProvider), isA<MonitorLive>());
  });

  test('warns when the strap loses skin contact', () async {
    await monitor().connect();
    bluetooth.strap.sendHeartRate(72, contact: true);
    expect(live().contactLost, isFalse);
    bluetooth.strap.sendHeartRate(0, contact: false);
    expect(live().contactLost, isTrue);
  });

  test('computes RMSSD over the last minute', () async {
    await monitor().connect();
    for (var i = 0; i < 12; i++) {
      bluetooth.strap.sendHeartRate(74, rr: [800, 820]);
      advance();
    }
    expect(live().rmssdMs, closeTo(20, 1));
  });

  test('disconnect releases the strap', () async {
    await monitor().connect();
    await monitor().disconnect();
    expect(container.read(monitorProvider), isA<MonitorIdle>());
    expect(bluetooth.strap.disconnected, isTrue);
  });

  test('demo mode runs the simulator through the same pipeline', () async {
    await monitor().startDemo();
    expect(live().simulated, isTrue);
    expect(live().batteryPercent, 82);
    for (var i = 0; i < 5; i++) {
      demo.link!.tick();
      advance();
    }
    expect(live().samples, hasLength(5));
    expect(live().samples.every((s) => s.isValid), isTrue);
    expect(live().sendsRrIntervals, isTrue);

    monitor().setSimulatedSkinContact(false);
    demo.link!.tick();
    expect(live().contactLost, isTrue);
    expect(live().skinContactSimulated, isFalse);
  });

  group('recorder', () {
    RecorderController recorder() => container.read(recorderProvider.notifier);

    test('saves the samples recorded between start and stop', () async {
      await monitor().connect();
      bluetooth.strap.sendHeartRate(60); // Before recording.
      advance();
      recorder().start();
      for (final bpm in [100, 120, 140]) {
        bluetooth.strap.sendHeartRate(bpm);
        advance();
      }
      final result = await recorder().stop();

      final session = (result! as RecordingSaved).session;
      expect(session.samples.map((s) => s.bpm), [100, 120, 140]);
      expect(session.duration, const Duration(seconds: 3));
      expect(session.maxHr, 185); // Default age 35.
      expect(container.read(recorderProvider), isA<RecorderIdle>());
      final saved = await container.read(sessionsProvider.future);
      expect(saved.single.id, session.id);
    });

    test('does not save a recording without valid readings', () async {
      await monitor().connect();
      recorder().start();
      bluetooth.strap.sendHeartRate(0, contact: false);
      expect(await recorder().stop(), isA<RecordingEmpty>());
      expect(await container.read(sessionsProvider.future), isEmpty);
    });

    test('saves what was recorded when the strap is disconnected', () async {
      container.listen(recorderProvider, (_, _) {});
      await monitor().connect();
      recorder().start();
      bluetooth.strap.sendHeartRate(120);
      advance();
      await monitor().disconnect();
      await pumpEventQueue();
      final saved = await container.read(sessionsProvider.future);
      expect(saved.single.samples.single.bpm, 120);
    });
  });
}

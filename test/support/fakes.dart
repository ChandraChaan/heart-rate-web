import 'dart:async';

import 'package:ble_device_simulator/ble_device_simulator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_rate_web/app.dart';
import 'package:heart_rate_web/core/file_saver.dart';
import 'package:heart_rate_web/core/preferences.dart';
import 'package:heart_rate_web/features/monitor/data/simulated_heart_rate.dart';
import 'package:heart_rate_web/features/monitor/domain/heart_rate_link.dart';
import 'package:heart_rate_web/features/monitor/presentation/monitor_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A strap the test drives by hand: push measurements, drop the
/// connection, and decide whether reconnecting works.
final class FakeStrap implements HeartRateLink {
  final _streams = <int, StreamController<List<int>>>{};
  final _connection = StreamController<bool>.broadcast(sync: true);
  var reconnectSucceeds = true;
  var reconnectAttempts = 0;
  var disconnected = false;

  @override
  String get deviceName => 'Polar H10 1234';

  @override
  bool get isSimulated => false;

  @override
  Stream<List<int>> notifications(int characteristic) => _streams
      .putIfAbsent(
        characteristic,
        () => StreamController<List<int>>.broadcast(sync: true),
      )
      .stream;

  @override
  Future<List<int>?> read(int characteristic) async => switch (characteristic) {
    HeartRateUuids.batteryLevel => [64],
    HeartRateUuids.bodySensorLocation => [1],
    _ => null,
  };

  @override
  Stream<bool> get connectionChanges => _connection.stream;

  @override
  Future<void> reconnect() async {
    reconnectAttempts++;
    if (!reconnectSucceeds) throw BluetoothFailure.connectionFailed;
    _connection.add(true);
  }

  @override
  Future<void> disconnect() async => disconnected = true;

  void sendHeartRate(int bpm, {List<double> rr = const [], bool? contact}) =>
      _streams[HeartRateUuids.heartRateMeasurement]?.add(
        GattEncoder.heartRate(
          bpm: bpm,
          skinContact: contact,
          rrIntervalsMs: rr,
        ),
      );

  void sendRaw(int characteristic, List<int> bytes) =>
      _streams[characteristic]?.add(bytes);

  void sendBattery(int percent) => _streams[HeartRateUuids.batteryLevel]?.add(
    GattEncoder.batteryLevel(percent),
  );

  void drop() => _connection.add(false);
}

/// Hands out [strap], or throws [failure].
final class FakeConnector implements HeartRateConnector {
  FakeConnector({this.isSupported = true, this.failure, FakeStrap? strap})
    : strap = strap ?? FakeStrap();

  @override
  final bool isSupported;
  BluetoothFailure? failure;
  final FakeStrap strap;
  var attempts = 0;

  @override
  Future<HeartRateLink> connect() async {
    attempts++;
    final failure = this.failure;
    if (failure != null) throw failure;
    return strap;
  }
}

/// The real demo connector, but ticked by the test instead of a timer.
final class ManualDemoConnector implements HeartRateConnector {
  SimulatedHeartRateLink? link;

  @override
  bool get isSupported => true;

  @override
  Future<HeartRateLink> connect() async {
    final created =
        await const SimulatedHeartRateConnector(
              tickInterval: Duration.zero,
            ).connect()
            as SimulatedHeartRateLink;
    return link = created;
  }
}

final class FakeFileSaver implements FileSaver {
  final saved = <({String fileName, String mimeType, String contents})>[];

  @override
  Future<void> save({
    required String fileName,
    required String mimeType,
    required String contents,
  }) async =>
      saved.add((fileName: fileName, mimeType: mimeType, contents: contents));
}

/// The whole app with fakes for Bluetooth, storage and downloads.
Future<Widget> testApp({
  required HeartRateConnector bluetooth,
  HeartRateConnector? demo,
  FileSaver? fileSaver,
  Map<String, Object> storage = const {},
}) async {
  SharedPreferences.setMockInitialValues(storage);
  final preferences = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      bluetoothConnectorProvider.overrideWithValue(bluetooth),
      demoConnectorProvider.overrideWithValue(demo ?? ManualDemoConnector()),
      fileSaverProvider.overrideWithValue(fileSaver ?? FakeFileSaver()),
    ],
    retry: (_, _) => null,
    child: const HeartRateApp(),
  );
}

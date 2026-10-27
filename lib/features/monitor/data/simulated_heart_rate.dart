import 'dart:async';
import 'dart:math' as math;

import 'package:ble_device_simulator/ble_device_simulator.dart';

import '../domain/heart_rate_link.dart';

/// Demo mode: a simulated chest strap from `ble_device_simulator` that sends
/// the same bytes a real one does.
final class SimulatedHeartRateConnector implements HeartRateConnector {
  const SimulatedHeartRateConnector({
    this.seed = 7,
    this.tickInterval = const Duration(seconds: 1),
  });

  final int seed;

  /// How often the strap sends a reading. Tests can pass [Duration.zero] and
  /// call [SimulatedHeartRateLink.tick] themselves.
  final Duration tickInterval;

  @override
  bool get isSupported => true;

  @override
  Future<HeartRateLink> connect() async {
    final device = DemoHeartRateStrap(seed: seed)..connect();
    if (tickInterval > Duration.zero) device.start(interval: tickInterval);
    return SimulatedHeartRateLink(device);
  }
}

final class SimulatedHeartRateLink
    implements HeartRateLink, SimulationControls {
  SimulatedHeartRateLink(this._device);

  final DemoHeartRateStrap _device;

  @override
  String get deviceName => _device.name;

  @override
  bool get isSimulated => true;

  @override
  Stream<List<int>> notifications(int characteristic) =>
      _device.notifications(characteristic);

  @override
  Future<List<int>?> read(int characteristic) async {
    try {
      return _device.read(characteristic);
    } on ArgumentError {
      return null;
    } on StateError {
      throw BluetoothFailure.connectionFailed;
    }
  }

  @override
  Stream<bool> get connectionChanges => _device.connectionState;

  @override
  Future<void> reconnect() async => _device.connect();

  @override
  Future<void> disconnect() async {
    _device.disconnect();
    await _device.dispose();
  }

  @override
  bool get skinContact => _device.skinContact;

  @override
  set skinContact(bool value) => _device.skinContact = value;

  @override
  void dropConnection() => _device.disconnect();

  /// Sends the next reading now.
  void tick() => _device.tick();
}

/// The simulator's chest strap, paced like a workout: heart rate climbs and
/// eases over four minutes instead of one, and RR-intervals rise and fall
/// with breathing, so the HRV readout has something real to show.
class DemoHeartRateStrap extends SimulatedHeartRateMonitor {
  DemoHeartRateStrap({super.seed})
    : super(name: 'Demo HR Strap', batteryLevel: 82, minBpm: 72, maxBpm: 176);

  /// One breath every four seconds.
  static const _breathSeconds = 4;

  @override
  Map<int, List<int>> onTick(int second) {
    if (!skinContact) return super.onTick(second);
    final bpm = drift(
      minBpm.toDouble(),
      maxBpm.toDouble(),
      period: 240,
      phase: -60,
    ).round();
    final meanRr = 60000 / bpm;
    // Variability shrinks as heart rate rises, as it does in people.
    final swing =
        meanRr * 0.04 * (1 - (bpm - minBpm) / (maxBpm - minBpm) * 0.7);
    final rr =
        meanRr + swing * math.sin(2 * math.pi * second / _breathSeconds + 0.6);
    return {
      GattCharacteristicIds.heartRateMeasurement: GattEncoder.heartRate(
        bpm: bpm,
        skinContact: true,
        rrIntervalsMs: [rr],
      ),
    };
  }
}

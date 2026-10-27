import 'dart:async';

import 'package:ble_gatt_parser/ble_gatt_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../data/simulated_heart_rate.dart';
import '../data/web_bluetooth_heart_rate.dart';
import '../domain/heart_rate_link.dart';
import '../domain/heart_rate_sample.dart';
import '../domain/hrv.dart';

/// A real strap through Web Bluetooth. Tests replace it.
final bluetoothConnectorProvider = Provider<HeartRateConnector>(
  (ref) => const WebBluetoothHeartRateConnector(),
);

/// The simulated strap used by demo mode.
final demoConnectorProvider = Provider<HeartRateConnector>(
  (ref) => const SimulatedHeartRateConnector(),
);

/// Whether this browser has Web Bluetooth.
final bluetoothSupportedProvider = Provider<bool>(
  (ref) => ref.watch(bluetoothConnectorProvider).isSupported,
);

/// Waits between automatic reconnect attempts after a drop.
const reconnectDelays = [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
];

final monitorProvider = NotifierProvider<MonitorController, MonitorState>(
  MonitorController.new,
);

sealed class MonitorState {
  const MonitorState();
}

/// Not connected. [failure] says why the last attempt failed, if it did.
final class MonitorIdle extends MonitorState {
  const MonitorIdle({this.failure});

  final BluetoothFailure? failure;
}

final class MonitorConnecting extends MonitorState {
  const MonitorConnecting({required this.simulated});

  final bool simulated;
}

enum LinkStatus { connected, reconnecting, lost }

/// Connected, or trying to get back after a drop.
final class MonitorLive extends MonitorState {
  const MonitorLive({
    required this.deviceName,
    required this.simulated,
    required this.connectedAt,
    this.status = LinkStatus.connected,
    this.samples = const [],
    this.batteryPercent,
    this.location,
    this.rmssdMs,
    this.sendsRrIntervals = false,
    this.skinContactSimulated = true,
  });

  final String deviceName;
  final bool simulated;
  final DateTime connectedAt;
  final LinkStatus status;

  /// Every reading since connecting, oldest first.
  final List<HeartRateSample> samples;
  final int? batteryPercent;
  final SensorLocation? location;

  /// RMSSD over the last minute.
  final double? rmssdMs;

  /// Whether any reading so far had RR-intervals.
  final bool sendsRrIntervals;

  /// Demo mode only: whether the simulated strap is "worn".
  final bool skinContactSimulated;

  HeartRateSample? get latest => samples.isEmpty ? null : samples.last;

  /// The strap reports that it isn't touching skin.
  bool get contactLost => latest?.contact == SensorContact.notDetected;

  MonitorLive copyWith({
    LinkStatus? status,
    List<HeartRateSample>? samples,
    int? batteryPercent,
    SensorLocation? location,
    double? Function()? rmssdMs,
    bool? sendsRrIntervals,
    bool? skinContactSimulated,
  }) => MonitorLive(
    deviceName: deviceName,
    simulated: simulated,
    connectedAt: connectedAt,
    status: status ?? this.status,
    samples: samples ?? this.samples,
    batteryPercent: batteryPercent ?? this.batteryPercent,
    location: location ?? this.location,
    rmssdMs: rmssdMs != null ? rmssdMs() : this.rmssdMs,
    sendsRrIntervals: sendsRrIntervals ?? this.sendsRrIntervals,
    skinContactSimulated: skinContactSimulated ?? this.skinContactSimulated,
  );
}

/// Connects to a strap or the demo, parses what it sends with
/// `ble_gatt_parser`, and keeps the connection alive.
class MonitorController extends Notifier<MonitorState> {
  HeartRateLink? _link;
  final _subscriptions = <StreamSubscription<Object?>>[];

  @override
  MonitorState build() {
    ref.onDispose(() => unawaited(_release()));
    return const MonitorIdle();
  }

  /// Opens the browser's device chooser and connects to the picked strap.
  Future<void> connect() =>
      _open(ref.read(bluetoothConnectorProvider), simulated: false);

  /// Connects to the simulated strap.
  Future<void> startDemo() =>
      _open(ref.read(demoConnectorProvider), simulated: true);

  Future<void> _open(
    HeartRateConnector connector, {
    required bool simulated,
  }) async {
    if (state is! MonitorIdle) return;
    state = MonitorConnecting(simulated: simulated);
    final HeartRateLink link;
    try {
      link = await connector.connect();
    } on BluetoothFailure catch (failure) {
      if (ref.mounted) state = MonitorIdle(failure: failure);
      return;
    }
    if (!ref.mounted) {
      await link.disconnect();
      return;
    }
    _link = link;
    state = MonitorLive(
      deviceName: link.deviceName,
      simulated: link.isSimulated,
      connectedAt: ref.read(clockProvider)(),
    );
    _subscriptions.addAll([
      link
          .notifications(HeartRateUuids.heartRateMeasurement)
          .listen(_onMeasurement),
      link.notifications(HeartRateUuids.batteryLevel).listen(_onBattery),
      link.connectionChanges.listen(_onConnectionChange),
    ]);
    await _readStaticValues(link);
  }

  Future<void> _readStaticValues(HeartRateLink link) async {
    try {
      final battery = await link.read(HeartRateUuids.batteryLevel);
      if (battery != null) _onBattery(battery);
      final location = await link.read(HeartRateUuids.bodySensorLocation);
      if (location == null || !ref.mounted || _link != link) return;
      final parsed = GattParser.tryParse(
        HeartRateUuids.bodySensorLocation,
        location,
      );
      if (parsed is BodySensorLocation) {
        _updateLive((live) => live.copyWith(location: parsed.location));
      }
    } on BluetoothFailure {
      // Optional values; the connection handling reports real problems.
    }
  }

  void _onMeasurement(List<int> bytes) {
    final parsed = GattParser.tryParse(
      HeartRateUuids.heartRateMeasurement,
      bytes,
    );
    if (parsed is! HeartRateMeasurement) return;
    final sample = HeartRateSample.fromMeasurement(
      ref.read(clockProvider)(),
      parsed,
    );
    _updateLive((live) {
      final samples = List<HeartRateSample>.unmodifiable([
        ...live.samples,
        sample,
      ]);
      return live.copyWith(
        samples: samples,
        rmssdMs: () => Hrv.rmssdOfSamples(samples, now: sample.time),
        sendsRrIntervals:
            live.sendsRrIntervals || sample.rrIntervalsMs.isNotEmpty,
      );
    });
  }

  void _onBattery(List<int> bytes) {
    final parsed = GattParser.tryParse(HeartRateUuids.batteryLevel, bytes);
    if (parsed is BatteryLevel) {
      _updateLive((live) => live.copyWith(batteryPercent: parsed.percent));
    }
  }

  void _onConnectionChange(bool connected) {
    final live = state;
    if (live is! MonitorLive) return;
    if (!connected && live.status == LinkStatus.connected) {
      _updateLive((live) => live.copyWith(status: LinkStatus.reconnecting));
      unawaited(_reconnectAutomatically(_link!));
    } else if (connected && live.status == LinkStatus.lost) {
      _updateLive((live) => live.copyWith(status: LinkStatus.connected));
    }
  }

  Future<void> _reconnectAutomatically(HeartRateLink link) async {
    for (final delay in reconnectDelays) {
      await Future<void>.delayed(delay);
      if (!ref.mounted || _link != link) return;
      if (await _tryReconnect(link)) return;
    }
    if (ref.mounted && _link == link) {
      _updateLive((live) => live.copyWith(status: LinkStatus.lost));
    }
  }

  /// Tries once to get a lost connection back.
  Future<void> reconnect() async {
    final link = _link;
    final live = state;
    if (link == null || live is! MonitorLive) return;
    if (live.status != LinkStatus.lost) return;
    _updateLive((live) => live.copyWith(status: LinkStatus.reconnecting));
    if (!await _tryReconnect(link) && ref.mounted && _link == link) {
      _updateLive((live) => live.copyWith(status: LinkStatus.lost));
    }
  }

  Future<bool> _tryReconnect(HeartRateLink link) async {
    try {
      await link.reconnect();
    } on BluetoothFailure {
      return false;
    }
    if (!ref.mounted || _link != link) return true;
    _updateLive((live) => live.copyWith(status: LinkStatus.connected));
    return true;
  }

  Future<void> disconnect() async {
    await _release();
    if (ref.mounted) state = const MonitorIdle();
  }

  /// Demo mode: takes the simulated strap off, or puts it back on.
  void setSimulatedSkinContact(bool worn) {
    if (_link case final SimulationControls controls) {
      controls.skinContact = worn;
      _updateLive((live) => live.copyWith(skinContactSimulated: worn));
    }
  }

  /// Demo mode: drops the connection, to show automatic reconnecting.
  void simulateDrop() {
    if (_link case final SimulationControls controls) controls.dropConnection();
  }

  void _updateLive(MonitorLive Function(MonitorLive live) update) {
    final live = state;
    if (live is MonitorLive) state = update(live);
  }

  Future<void> _release() async {
    final link = _link;
    _link = null;
    // Stop listening right away; nothing needs the cancels to finish.
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    await link?.disconnect();
  }
}

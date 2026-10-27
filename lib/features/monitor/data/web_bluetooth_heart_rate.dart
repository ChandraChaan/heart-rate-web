import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:ble_device_simulator/ble_device_simulator.dart' show uuid128;
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';

import '../domain/heart_rate_link.dart';

/// A real strap, through the browser's Web Bluetooth API.
final class WebBluetoothHeartRateConnector implements HeartRateConnector {
  const WebBluetoothHeartRateConnector();

  static const _connectTimeout = Duration(seconds: 15);

  @override
  bool get isSupported => FlutterWebBluetooth.instance.isBluetoothApiSupported;

  @override
  Future<HeartRateLink> connect() async {
    if (!isSupported) throw BluetoothFailure.unsupported;
    final BluetoothDevice device;
    try {
      device = await FlutterWebBluetooth.instance.requestDevice(
        RequestOptionsBuilder(
          [
            RequestFilterBuilder(
              services: [uuid128(HeartRateUuids.heartRateService)],
            ),
          ],
          optionalServices: [uuid128(HeartRateUuids.batteryService)],
        ),
        checkingAvailability: true,
      );
    } on Object catch (error, stackTrace) {
      throw _failureOf(error, stackTrace);
    }
    final link = _WebBluetoothHeartRateLink(device);
    await link.reconnect();
    return link;
  }
}

final class _WebBluetoothHeartRateLink implements HeartRateLink {
  _WebBluetoothHeartRateLink(this._device) {
    _connectedSubscription = _device.connected.listen(_connection.add);
  }

  final BluetoothDevice _device;
  final _connection = StreamController<bool>.broadcast();
  late final StreamSubscription<bool> _connectedSubscription;
  final _streams = <int, StreamController<List<int>>>{};
  final _valueSubscriptions = <StreamSubscription<Object?>>[];
  final _characteristics = <int, BluetoothCharacteristic>{};

  @override
  String get deviceName => _device.name ?? 'Heart-rate sensor';

  @override
  bool get isSimulated => false;

  @override
  Stream<List<int>> notifications(int characteristic) =>
      _controller(characteristic).stream;

  StreamController<List<int>> _controller(int characteristic) =>
      _streams.putIfAbsent(characteristic, StreamController.broadcast);

  @override
  Future<List<int>?> read(int characteristic) async {
    final found = _characteristics[characteristic];
    if (found == null) return null;
    try {
      return _bytes(await found.readValue());
    } on Object catch (error, stackTrace) {
      developer.log(
        'Reading 0x${characteristic.toRadixString(16)} failed',
        name: 'heart_rate_web',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Stream<bool> get connectionChanges => _connection.stream;

  @override
  Future<void> reconnect() async {
    await _cancelValueSubscriptions();
    _characteristics.clear();
    try {
      await _device.connect(
        timeout: WebBluetoothHeartRateConnector._connectTimeout,
      );
      final services = await _device.discoverServices();
      final heartRate = _service(services, HeartRateUuids.heartRateService);
      if (heartRate == null) throw BluetoothFailure.noHeartRateService;

      final measurement = await heartRate.getCharacteristic(
        uuid128(HeartRateUuids.heartRateMeasurement),
      );
      await _subscribe(HeartRateUuids.heartRateMeasurement, measurement);
      await _find(heartRate, HeartRateUuids.bodySensorLocation);

      final battery = _service(services, HeartRateUuids.batteryService);
      if (battery != null) {
        final level = await _find(battery, HeartRateUuids.batteryLevel);
        if (level != null && level.properties.notify) {
          await _subscribe(HeartRateUuids.batteryLevel, level);
        }
      }
    } on BluetoothFailure {
      _device.disconnect();
      rethrow;
    } on Object catch (error, stackTrace) {
      _device.disconnect();
      throw _failureOf(error, stackTrace);
    }
  }

  @override
  Future<void> disconnect() async {
    await _cancelValueSubscriptions();
    _device.disconnect();
    await _connectedSubscription.cancel();
    await Future.wait([
      _connection.close(),
      for (final stream in _streams.values) stream.close(),
    ]);
  }

  BluetoothService? _service(List<BluetoothService> services, int uuid) {
    final full = uuid128(uuid);
    for (final service in services) {
      if (service.uuid.toLowerCase() == full) return service;
    }
    return null;
  }

  /// Looks up an optional characteristic and remembers it for [read].
  Future<BluetoothCharacteristic?> _find(
    BluetoothService service,
    int uuid,
  ) async {
    try {
      final characteristic = await service.getCharacteristic(uuid128(uuid));
      _characteristics[uuid] = characteristic;
      return characteristic;
    } on Object catch (error, stackTrace) {
      developer.log(
        'Sensor has no 0x${uuid.toRadixString(16)}',
        name: 'heart_rate_web',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> _subscribe(
    int uuid,
    BluetoothCharacteristic characteristic,
  ) async {
    _characteristics[uuid] = characteristic;
    _valueSubscriptions.add(
      characteristic.value.listen(
        (data) => _controller(uuid).add(_bytes(data)),
      ),
    );
    await characteristic.startNotifications();
  }

  Future<void> _cancelValueSubscriptions() async {
    final subscriptions = List.of(_valueSubscriptions);
    _valueSubscriptions.clear();
    await Future.wait(subscriptions.map((s) => s.cancel()));
  }

  static List<int> _bytes(ByteData data) => List.unmodifiable(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
}

BluetoothFailure _failureOf(Object error, StackTrace stackTrace) {
  final failure = switch (error) {
    BluetoothFailure() => error,
    UserCancelledDialogError() => BluetoothFailure.cancelled,
    DeviceNotFoundError() => BluetoothFailure.cancelled,
    NativeAPINotImplementedError() => BluetoothFailure.unsupported,
    BluetoothAdapterNotAvailable() => BluetoothFailure.adapterUnavailable,
    PermissionError() ||
    PolicyError() ||
    SecurityError() => BluetoothFailure.permissionDenied,
    NotFoundError() => BluetoothFailure.noHeartRateService,
    _ => BluetoothFailure.connectionFailed,
  };
  developer.log(
    'Web Bluetooth: $failure',
    name: 'heart_rate_web',
    error: error,
    stackTrace: stackTrace,
  );
  return failure;
}

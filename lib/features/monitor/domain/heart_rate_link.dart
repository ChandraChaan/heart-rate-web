/// The Bluetooth side of the app, kept behind interfaces so the UI, the
/// recorder and the exports run the same way against a real strap (Web
/// Bluetooth) and the simulator (demo mode and tests).
library;

/// Opens connections to heart-rate sensors.
abstract interface class HeartRateConnector {
  /// Whether this browser can talk to Bluetooth devices at all.
  bool get isSupported;

  /// Asks the user to pick a sensor and connects to it.
  ///
  /// Throws a [BluetoothFailure].
  Future<HeartRateLink> connect();
}

/// A connected heart-rate sensor that hands out raw GATT values.
///
/// Values are parsed by the caller with `ble_gatt_parser`, so a strap and the
/// simulator go through the same code.
abstract interface class HeartRateLink {
  String get deviceName;

  /// True for the built-in simulator.
  bool get isSimulated;

  /// Values notified by [characteristic], a 16-bit UUID such as `0x2A37`.
  /// The stream stays open across [reconnect].
  Stream<List<int>> notifications(int characteristic);

  /// Reads [characteristic], or returns null if the sensor doesn't have it.
  Future<List<int>?> read(int characteristic);

  /// Emits false when the connection drops and true when it comes back.
  Stream<bool> get connectionChanges;

  /// Connects again to the same sensor, without asking the user to pick it.
  ///
  /// Throws a [BluetoothFailure].
  Future<void> reconnect();

  /// Disconnects and releases the sensor. The link can't be used afterwards.
  Future<void> disconnect();
}

/// Extra controls the simulator offers, so demo mode can show what happens
/// when a strap slips off or goes out of range.
abstract interface class SimulationControls {
  bool get skinContact;
  set skinContact(bool value);

  /// Drops the connection like a sensor going out of range.
  void dropConnection();
}

/// Why connecting to a sensor failed.
enum BluetoothFailure implements Exception {
  /// The browser has no Web Bluetooth (Safari, Firefox, iOS).
  unsupported,

  /// Bluetooth is off, or the computer has no Bluetooth adapter.
  adapterUnavailable,

  /// The user closed the device chooser without picking a sensor.
  cancelled,

  /// The browser, the operating system or a policy blocked Bluetooth.
  permissionDenied,

  /// The device doesn't offer the Heart Rate service.
  noHeartRateService,

  /// The sensor didn't answer, or the connection dropped while setting up.
  connectionFailed,
}

/// 16-bit UUIDs used by the app.
abstract final class HeartRateUuids {
  static const heartRateService = 0x180D;
  static const batteryService = 0x180F;
  static const heartRateMeasurement = 0x2A37;
  static const bodySensorLocation = 0x2A38;
  static const batteryLevel = 0x2A19;
}

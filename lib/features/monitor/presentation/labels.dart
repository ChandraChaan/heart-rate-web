import 'package:ble_gatt_parser/ble_gatt_parser.dart' show SensorLocation;

import '../../../l10n/app_localizations.dart';
import '../domain/heart_rate_link.dart';
import '../domain/heart_rate_zones.dart';

/// User-facing names for domain values.
extension MonitorLabels on AppLocalizations {
  String zoneName(HeartRateZone zone) => switch (zone) {
    HeartRateZone.rest => zoneRest,
    HeartRateZone.zone1 => zone1,
    HeartRateZone.zone2 => zone2,
    HeartRateZone.zone3 => zone3,
    HeartRateZone.zone4 => zone4,
    HeartRateZone.zone5 => zone5,
  };

  String zoneShortName(HeartRateZone zone) =>
      zone == HeartRateZone.rest ? zoneShortRest : zoneShort(zone.number);

  String zoneRangeOf(HeartRateZones zones, HeartRateZone zone) {
    final upper = zones.upperBpm(zone);
    if (zone == HeartRateZone.rest) return zoneRangeBelow(upper! + 1);
    return upper == null
        ? zoneRangeOpen(zones.lowerBpm(zone))
        : zoneRange(zones.lowerBpm(zone), upper);
  }

  String failureMessage(BluetoothFailure failure) => switch (failure) {
    BluetoothFailure.unsupported => failureUnsupported,
    BluetoothFailure.adapterUnavailable => failureAdapterUnavailable,
    BluetoothFailure.cancelled => failureCancelled,
    BluetoothFailure.permissionDenied => failurePermissionDenied,
    BluetoothFailure.noHeartRateService => failureNoHeartRateService,
    BluetoothFailure.connectionFailed => failureConnectionFailed,
  };

  String locationName(SensorLocation location) => switch (location) {
    SensorLocation.other => locationOther,
    SensorLocation.chest => locationChest,
    SensorLocation.wrist => locationWrist,
    SensorLocation.finger => locationFinger,
    SensorLocation.hand => locationHand,
    SensorLocation.earLobe => locationEarLobe,
    SensorLocation.foot => locationFoot,
    SensorLocation.unknown => locationUnknown,
  };
}

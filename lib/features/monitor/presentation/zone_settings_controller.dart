import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences.dart';
import '../domain/heart_rate_zones.dart';

final zoneSettingsProvider =
    NotifierProvider<ZoneSettingsController, ZoneSettings>(
      ZoneSettingsController.new,
    );

/// The user's age and optional measured max HR, kept in browser storage.
class ZoneSettingsController extends Notifier<ZoneSettings> {
  static const _ageKey = 'zones.age';
  static const _maxHrKey = 'zones.maxHr';

  @override
  ZoneSettings build() {
    final preferences = ref.watch(sharedPreferencesProvider);
    return ZoneSettings(
      age: preferences.getInt(_ageKey) ?? ZoneSettings.defaultAge,
      measuredMaxHr: preferences.getInt(_maxHrKey),
    );
  }

  Future<void> save(ZoneSettings settings) async {
    state = settings;
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.setInt(_ageKey, settings.age);
    final maxHr = settings.measuredMaxHr;
    if (maxHr == null) {
      await preferences.remove(_maxHrKey);
    } else {
      await preferences.setInt(_maxHrKey, maxHr);
    }
  }
}

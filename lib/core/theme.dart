import 'package:flutter/material.dart';

import '../features/monitor/domain/heart_rate_zones.dart';

abstract final class AppTheme {
  static const _seed = Color(0xFFC62828);

  static ThemeData light() => _theme(Brightness.light, ZoneColors.light);

  static ThemeData dark() => _theme(Brightness.dark, ZoneColors.dark);

  static ThemeData _theme(Brightness brightness, ZoneColors zones) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      extensions: [zones],
      cardTheme: const CardThemeData(margin: EdgeInsets.zero),
    );
  }
}

/// One colour per heart-rate zone, the usual grey → blue → green → yellow →
/// orange → red. Zones are always labelled too, never shown by colour alone.
@immutable
final class ZoneColors extends ThemeExtension<ZoneColors> {
  const ZoneColors(this.colors);

  static const light = ZoneColors({
    HeartRateZone.rest: Color(0xFF90A4AE),
    HeartRateZone.zone1: Color(0xFF42A5F5),
    HeartRateZone.zone2: Color(0xFF43A047),
    HeartRateZone.zone3: Color(0xFFFDD835),
    HeartRateZone.zone4: Color(0xFFFB8C00),
    HeartRateZone.zone5: Color(0xFFE53935),
  });

  static const dark = ZoneColors({
    HeartRateZone.rest: Color(0xFF78909C),
    HeartRateZone.zone1: Color(0xFF64B5F6),
    HeartRateZone.zone2: Color(0xFF66BB6A),
    HeartRateZone.zone3: Color(0xFFFFEE58),
    HeartRateZone.zone4: Color(0xFFFFA726),
    HeartRateZone.zone5: Color(0xFFEF5350),
  });

  final Map<HeartRateZone, Color> colors;

  Color of(HeartRateZone zone) => colors[zone]!;

  static ZoneColors fromContext(BuildContext context) =>
      Theme.of(context).extension<ZoneColors>() ?? light;

  @override
  ZoneColors copyWith({Map<HeartRateZone, Color>? colors}) =>
      ZoneColors(colors ?? this.colors);

  @override
  ZoneColors lerp(ZoneColors? other, double t) {
    if (other == null) return this;
    return ZoneColors({
      for (final zone in HeartRateZone.values)
        zone: Color.lerp(of(zone), other.of(zone), t)!,
    });
  }
}

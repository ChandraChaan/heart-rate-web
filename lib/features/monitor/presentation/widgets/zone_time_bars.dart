import 'package:flutter/material.dart';

import '../../../../core/formatting.dart';
import '../../../../core/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/heart_rate_zones.dart';
import '../labels.dart';

/// Time spent in each zone, zone 5 at the top, as labelled bars.
class ZoneTimeBars extends StatelessWidget {
  const ZoneTimeBars({
    required this.timeInZones,
    required this.maxHr,
    super.key,
  });

  final Map<HeartRateZone, Duration> timeInZones;
  final int maxHr;

  @override
  Widget build(BuildContext context) {
    final total = timeInZones.values.fold(Duration.zero, (a, b) => a + b);
    return Column(
      children: [
        for (final zone in HeartRateZone.values.reversed)
          _ZoneRow(
            key: ValueKey(zone),
            zone: zone,
            zones: HeartRateZones(maxHr),
            time: timeInZones[zone] ?? Duration.zero,
            total: total,
          ),
      ],
    );
  }
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.zone,
    required this.zones,
    required this.time,
    required this.total,
    super.key,
  });

  final HeartRateZone zone;
  final HeartRateZones zones;
  final Duration time;
  final Duration total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fraction = total == Duration.zero
        ? 0.0
        : time.inMilliseconds / total.inMilliseconds;
    final percent = (fraction * 100).round();
    return Semantics(
      label:
          '${l10n.zoneName(zone)}, ${l10n.zoneRangeOf(zones, zone)}: '
          '${formatDuration(time)}, $percent%',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  l10n.zoneShortName(zone),
                  style: theme.textTheme.labelLarge,
                ),
              ),
              Expanded(
                child: Tooltip(
                  message:
                      '${l10n.zoneName(zone)} · ${l10n.zoneRangeOf(zones, zone)}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(
                          height: 18,
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        FractionallySizedBox(
                          widthFactor: fraction,
                          child: Container(
                            height: 18,
                            color: ZoneColors.fromContext(context).of(zone),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 96,
                child: Text(
                  '${formatDuration(time)}  $percent%',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

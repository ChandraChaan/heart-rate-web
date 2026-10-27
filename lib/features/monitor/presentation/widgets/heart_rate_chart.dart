import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/formatting.dart';
import '../../../../core/theme.dart';
import '../../domain/heart_rate_sample.dart';
import '../../domain/heart_rate_zones.dart';

/// Heart rate over time, drawn over coloured zone bands.
///
/// With a [window], it shows that much time up to the newest sample (the
/// live view). Without one it shows every sample from [start].
class HeartRateChart extends StatelessWidget {
  const HeartRateChart({
    required this.samples,
    required this.maxHr,
    required this.semanticLabel,
    this.window,
    this.start,
    super.key,
  });

  final List<HeartRateSample> samples;
  final int maxHr;
  final Duration? window;
  final DateTime? start;
  final String semanticLabel;

  /// A gap longer than this between readings breaks the line.
  static const _maxGap = Duration(seconds: 5);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final zoneColors = ZoneColors.fromContext(context);
    final zones = HeartRateZones(maxHr);
    final data = _ChartData.from(
      samples,
      window: window,
      start: start,
      floor: zones.lowerBpm(HeartRateZone.zone1) - 15,
      ceiling: maxHr + 5,
    );
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: LineChart(
          duration: Duration.zero,
          LineChartData(
            minX: data.minX,
            maxX: data.maxX,
            minY: data.minY,
            maxY: data.maxY,
            clipData: const FlClipData.all(),
            lineTouchData: const LineTouchData(enabled: false),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (_) => FlLine(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ),
            rangeAnnotations: RangeAnnotations(
              horizontalRangeAnnotations: [
                for (final zone in HeartRateZone.values.skip(1))
                  HorizontalRangeAnnotation(
                    y1: zones.lowerBpm(zone).toDouble(),
                    y2: zone == HeartRateZone.zone5
                        ? data.maxY
                        : zones.upperBpm(zone)! + 1,
                    color: zoneColors.of(zone).withValues(alpha: 0.18),
                  ),
              ],
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: 20,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(value.round().toString(), style: labelStyle),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: data.xInterval,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      _timeLabel(value, live: window != null),
                      style: labelStyle,
                    ),
                  ),
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: data.spots,
                color: scheme.onSurface,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _timeLabel(double seconds, {required bool live}) {
    final text = formatDuration(Duration(seconds: seconds.abs().round()));
    return live && seconds < 0 ? '−$text' : text;
  }
}

/// Spots and axis ranges, worked out once per build.
final class _ChartData {
  const _ChartData({
    required this.spots,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.xInterval,
  });

  factory _ChartData.from(
    List<HeartRateSample> samples, {
    required Duration? window,
    required DateTime? start,
    required int floor,
    required int ceiling,
  }) {
    final DateTime origin;
    final double minX, maxX;
    var visible = samples;
    if (window != null) {
      origin = samples.isEmpty ? DateTime.utc(0) : samples.last.time;
      final from = origin.subtract(window);
      var first = samples.length;
      while (first > 0 && !samples[first - 1].time.isBefore(from)) {
        first--;
      }
      visible = samples.sublist(first);
      minX = -window.inSeconds.toDouble();
      maxX = 0;
    } else {
      origin =
          start ?? (samples.isEmpty ? DateTime.utc(0) : samples.first.time);
      minX = 0;
      maxX = samples.isEmpty
          ? 60
          : math
                .max(60, samples.last.time.difference(origin).inSeconds)
                .toDouble();
    }

    final spots = <FlSpot>[];
    var low = floor, high = ceiling;
    HeartRateSample? previous;
    for (final sample in visible) {
      if (!sample.isValid) {
        if (spots.isNotEmpty && !spots.last.isNull()) {
          spots.add(FlSpot.nullSpot);
        }
        previous = null;
        continue;
      }
      if (previous != null &&
          sample.time.difference(previous.time) > HeartRateChart._maxGap) {
        spots.add(FlSpot.nullSpot);
      }
      final x = sample.time.difference(origin).inMilliseconds / 1000;
      spots.add(FlSpot(x, sample.bpm.toDouble()));
      low = math.min(low, sample.bpm - 5);
      high = math.max(high, sample.bpm + 5);
      previous = sample;
    }

    final span = maxX - minX;
    final xInterval = span <= 300
        ? 60.0
        : span <= 1800
        ? 300.0
        : span <= 3 * 3600
        ? 900.0
        : 3600.0;
    return _ChartData(
      spots: spots,
      minX: minX,
      maxX: maxX,
      minY: (low ~/ 10 * 10).toDouble(),
      maxY: ((high + 9) ~/ 10 * 10).toDouble(),
      xInterval: xInterval,
    );
  }

  final List<FlSpot> spots;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double xInterval;
}

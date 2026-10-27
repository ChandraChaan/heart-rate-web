import 'recorded_session.dart';
import 'session_stats.dart';

/// Activity types TCX knows about. Training apps use it to pick the sport.
enum TcxSport {
  running('Running'),
  biking('Biking'),
  other('Other');

  const TcxSport(this.xmlName);

  final String xmlName;
}

const _kilojoulesPerKilocalorie = 4.184;

/// Garmin Training Center XML (TCX v2), which Strava, Garmin Connect,
/// TrainingPeaks, Runalyze and most training apps import.
///
/// One lap with the session's summary, and a trackpoint for every valid
/// reading. Readings without skin contact are left out, since TCX heart
/// rates must be at least 1 bpm.
String sessionToTcx(
  RecordedSession session, {
  TcxSport sport = TcxSport.other,
}) {
  final stats = SessionStats.of(session);
  final start = _time(session.startedAt);
  final energy = stats.energyKj;
  final calories = energy == null
      ? 0
      : (energy / _kilojoulesPerKilocalorie).round().clamp(0, 65535);
  final buffer = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln(
      '<TrainingCenterDatabase '
      'xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2" '
      'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
      'xsi:schemaLocation="'
      'http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2 '
      'http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd">',
    )
    ..writeln('  <Activities>')
    ..writeln('    <Activity Sport="${sport.xmlName}">')
    ..writeln('      <Id>$start</Id>')
    ..writeln('      <Lap StartTime="$start">')
    ..writeln(
      '        <TotalTimeSeconds>'
      '${(session.duration.inMilliseconds / 1000).toStringAsFixed(1)}'
      '</TotalTimeSeconds>',
    )
    ..writeln('        <DistanceMeters>0.0</DistanceMeters>')
    ..writeln('        <Calories>$calories</Calories>');
  if (stats.averageBpm case final average?) {
    buffer.writeln(
      '        <AverageHeartRateBpm><Value>${_bpm(average)}</Value>'
      '</AverageHeartRateBpm>',
    );
  }
  if (stats.maxBpm case final max?) {
    buffer.writeln(
      '        <MaximumHeartRateBpm><Value>${_bpm(max)}</Value>'
      '</MaximumHeartRateBpm>',
    );
  }
  buffer
    ..writeln('        <Intensity>Active</Intensity>')
    ..writeln('        <TriggerMethod>Manual</TriggerMethod>')
    ..writeln('        <Track>');
  for (final sample in session.samples) {
    if (!sample.isValid) continue;
    buffer.writeln(
      '          <Trackpoint><Time>${_time(sample.time)}</Time>'
      '<HeartRateBpm><Value>${_bpm(sample.bpm)}</Value></HeartRateBpm>'
      '</Trackpoint>',
    );
  }
  buffer
    ..writeln('        </Track>')
    ..writeln('      </Lap>')
    ..writeln(
      '      <Notes>${_escape('Recorded with Heart Rate Web from '
      '${session.deviceName}${session.simulated ? ' (simulated)' : ''}')}'
      '</Notes>',
    )
    ..writeln('    </Activity>')
    ..writeln('  </Activities>')
    ..writeln('</TrainingCenterDatabase>');
  return buffer.toString();
}

String _time(DateTime time) => time.toUtc().toIso8601String();

/// TCX heart rates are unsigned bytes from 1.
int _bpm(int bpm) => bpm.clamp(1, 255);

String _escape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

import 'package:ble_gatt_parser/ble_gatt_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_web/features/monitor/domain/heart_rate_sample.dart';
import 'package:heart_rate_web/features/sessions/domain/tcx_export.dart';
import 'package:xml/xml.dart';

import '../../support/fixtures.dart';

const _ns = 'http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2';

void main() {
  XmlElement only(XmlElement parent, String name) =>
      parent.findElements(name, namespaceUri: _ns).single;

  List<String> childNames(XmlElement element) =>
      element.childElements.map((e) => e.name.local).toList();

  final session = sessionOf([
    ...samplesOf([120, 140, 160]),
    HeartRateSample(
      time: t0.add(const Duration(seconds: 3)),
      bpm: 0,
      contact: SensorContact.notDetected,
    ),
    HeartRateSample(
      time: t0.add(const Duration(seconds: 4)),
      bpm: 150,
      energyKj: 50,
    ),
  ]);

  test('is well-formed XML in the TCX v2 namespace', () {
    final document = XmlDocument.parse(sessionToTcx(session));
    final root = document.rootElement;
    expect(root.name.local, 'TrainingCenterDatabase');
    expect(root.name.namespaceUri, _ns);
    expect(document.declaration?.getAttribute('encoding'), 'UTF-8');
  });

  test('follows the element order the TCX schema requires', () {
    final root = XmlDocument.parse(sessionToTcx(session)).rootElement;
    expect(childNames(root), ['Activities']);
    final activity = only(only(root, 'Activities'), 'Activity');
    expect(childNames(activity), ['Id', 'Lap', 'Notes']);
    expect(childNames(only(activity, 'Lap')), [
      'TotalTimeSeconds',
      'DistanceMeters',
      'Calories',
      'AverageHeartRateBpm',
      'MaximumHeartRateBpm',
      'Intensity',
      'TriggerMethod',
      'Track',
    ]);
    for (final point in only(only(activity, 'Lap'), 'Track').childElements) {
      expect(point.name.local, 'Trackpoint');
      expect(childNames(point), ['Time', 'HeartRateBpm']);
      expect(childNames(only(point, 'HeartRateBpm')), ['Value']);
    }
  });

  test('carries the summary and one trackpoint per valid reading', () {
    final activity = only(
      only(XmlDocument.parse(sessionToTcx(session)).rootElement, 'Activities'),
      'Activity',
    );
    final lap = only(activity, 'Lap');
    expect(activity.getAttribute('Sport'), 'Other');
    expect(only(activity, 'Id').innerText, '2026-10-27T09:30:00.000Z');
    expect(lap.getAttribute('StartTime'), '2026-10-27T09:30:00.000Z');
    expect(only(lap, 'TotalTimeSeconds').innerText, '5.0');
    expect(only(only(lap, 'AverageHeartRateBpm'), 'Value').innerText, '143');
    expect(only(only(lap, 'MaximumHeartRateBpm'), 'Value').innerText, '160');
    expect(only(lap, 'Intensity').innerText, 'Active');

    final points = only(lap, 'Track').childElements.toList();
    expect(points, hasLength(4)); // The lost-contact reading is left out.
    expect(only(points.first, 'Time').innerText, '2026-10-27T09:30:00.000Z');
    expect(
      points.map((p) => only(only(p, 'HeartRateBpm'), 'Value').innerText),
      ['120', '140', '160', '150'],
    );
  });

  test('converts energy to kilocalories when the strap reports it', () {
    HeartRateSample at(int second, int energy) => HeartRateSample(
      time: t0.add(Duration(seconds: second)),
      bpm: 130,
      energyKj: energy,
    );
    final lap = XmlDocument.parse(
      sessionToTcx(sessionOf([at(0, 100), at(1, 518)])),
    ).findAllElements('Calories', namespaceUri: _ns).single;
    expect(lap.innerText, '100'); // 418 kJ.
    expect(
      XmlDocument.parse(
        sessionToTcx(session),
      ).findAllElements('Calories', namespaceUri: _ns).single.innerText,
      '0',
    );
  });

  test('sets the sport and escapes the device name', () {
    final xml = sessionToTcx(session, sport: TcxSport.running);
    final activity = XmlDocument.parse(
      xml,
    ).findAllElements('Activity', namespaceUri: _ns).single;
    expect(activity.getAttribute('Sport'), 'Running');
    expect(
      only(activity, 'Notes').innerText,
      'Recorded with Heart Rate Web from Polar H10 <Test & Co>',
    );
    expect(xml, contains('Polar H10 &lt;Test &amp; Co&gt;'));
  });

  test('leaves out heart-rate summaries when nothing valid was recorded', () {
    final lap = XmlDocument.parse(
      sessionToTcx(sessionOf([HeartRateSample(time: t0, bpm: 0)])),
    ).findAllElements('Lap', namespaceUri: _ns).single;
    expect(childNames(lap), [
      'TotalTimeSeconds',
      'DistanceMeters',
      'Calories',
      'Intensity',
      'TriggerMethod',
      'Track',
    ]);
    expect(only(lap, 'Track').childElements, isEmpty);
  });
}

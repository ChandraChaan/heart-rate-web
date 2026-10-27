import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_web/features/monitor/domain/heart_rate_link.dart';
import 'package:heart_rate_web/features/monitor/presentation/monitor_controller.dart';

import 'support/fakes.dart';

void main() {
  Future<void> useSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('connect', () {
    testWidgets('offers connecting and demo mode', (tester) async {
      await tester.pumpWidget(await testApp(bluetooth: FakeConnector()));
      expect(find.text('Connect a strap'), findsOneWidget);
      expect(find.text('Try demo mode'), findsOneWidget);
      expect(find.byKey(const Key('unsupported')), findsNothing);
      expect(find.textContaining('never leave your browser'), findsOneWidget);
    });

    testWidgets('explains when the browser has no Web Bluetooth', (
      tester,
    ) async {
      await tester.pumpWidget(
        await testApp(bluetooth: FakeConnector(isSupported: false)),
      );
      expect(find.byKey(const Key('unsupported')), findsOneWidget);
      expect(find.textContaining('Firefox'), findsOneWidget);
      expect(find.textContaining('iPhone'), findsOneWidget);
      expect(find.byKey(const Key('connect')), findsNothing);
      expect(find.byKey(const Key('demo')), findsOneWidget);
    });

    testWidgets('shows why connecting failed, and can retry', (tester) async {
      final bluetooth = FakeConnector(
        failure: BluetoothFailure.permissionDenied,
      );
      await tester.pumpWidget(await testApp(bluetooth: bluetooth));
      await tester.tap(find.byKey(const Key('connect')));
      await tester.pump();
      expect(find.byKey(const Key('failure')), findsOneWidget);
      expect(
        find.textContaining('Bluetooth access was blocked'),
        findsOneWidget,
      );

      bluetooth.failure = null;
      await tester.tap(find.byKey(const Key('connect')));
      await tester.pump();
      expect(bluetooth.attempts, 2);
      expect(find.text('Polar H10 1234'), findsOneWidget);
      expect(find.byKey(const Key('failure')), findsNothing);
    });

    testWidgets('shows readings from a strap', (tester) async {
      final bluetooth = FakeConnector();
      await tester.pumpWidget(await testApp(bluetooth: bluetooth));
      await tester.tap(find.byKey(const Key('connect')));
      await tester.pump();

      expect(find.text('Waiting for the first reading…'), findsOneWidget);
      expect(find.text('Battery 64%'), findsOneWidget);
      expect(find.text('Chest'), findsOneWidget);
      expect(find.byKey(const Key('simulated-badge')), findsNothing);

      bluetooth.strap.sendHeartRate(150, contact: true);
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(const Key('bpm'))).data, '150');
      // 150 of 185 (220 − 35) is 81%: zone 4.
      expect(find.text('Zone 4 · Hard'), findsOneWidget);
      expect(
        find.text('This sensor doesn\'t send RR-intervals.'),
        findsOneWidget,
      );

      bluetooth.strap.sendHeartRate(0, contact: false);
      await tester.pump();
      expect(find.byKey(const Key('contact-warning')), findsOneWidget);
    });

    testWidgets('reconnects automatically after a drop', (tester) async {
      final bluetooth = FakeConnector();
      await tester.pumpWidget(await testApp(bluetooth: bluetooth));
      await tester.tap(find.byKey(const Key('connect')));
      await tester.pump();

      bluetooth.strap.drop();
      await tester.pump();
      expect(find.byKey(const Key('status-reconnecting')), findsOneWidget);

      await tester.pump(reconnectDelays.first);
      expect(find.byKey(const Key('status-connected')), findsOneWidget);
      expect(bluetooth.strap.reconnectAttempts, 1);
    });

    testWidgets('offers a manual reconnect when retries run out', (
      tester,
    ) async {
      final bluetooth = FakeConnector();
      bluetooth.strap.reconnectSucceeds = false;
      await tester.pumpWidget(await testApp(bluetooth: bluetooth));
      await tester.tap(find.byKey(const Key('connect')));
      await tester.pump();

      bluetooth.strap.drop();
      for (final delay in reconnectDelays) {
        await tester.pump(delay);
      }
      expect(bluetooth.strap.reconnectAttempts, reconnectDelays.length);
      expect(find.byKey(const Key('status-lost')), findsOneWidget);

      bluetooth.strap.reconnectSucceeds = true;
      await tester.tap(find.byKey(const Key('reconnect')));
      await tester.pump();
      expect(find.byKey(const Key('status-connected')), findsOneWidget);
    });

    testWidgets('disconnect returns to the start', (tester) async {
      final bluetooth = FakeConnector();
      await tester.pumpWidget(await testApp(bluetooth: bluetooth));
      await tester.tap(find.byKey(const Key('connect')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('disconnect')));
      await tester.pump();
      expect(find.byKey(const Key('connect')), findsOneWidget);
      expect(bluetooth.strap.disconnected, isTrue);
    });
  });

  group('demo mode', () {
    Future<ManualDemoConnector> startDemo(
      WidgetTester tester, {
      FakeFileSaver? fileSaver,
    }) async {
      final demo = ManualDemoConnector();
      await tester.pumpWidget(
        await testApp(
          bluetooth: FakeConnector(),
          demo: demo,
          fileSaver: fileSaver,
        ),
      );
      await tester.tap(find.byKey(const Key('demo')));
      await tester.pump();
      return demo;
    }

    Future<void> tick(
      WidgetTester tester,
      ManualDemoConnector demo, [
      int seconds = 1,
    ]) async {
      for (var i = 0; i < seconds; i++) {
        await tester.pump(const Duration(seconds: 1));
        demo.link!.tick();
        await tester.pump();
      }
    }

    testWidgets('is clearly labelled as simulated', (tester) async {
      final demo = await startDemo(tester);
      expect(find.byKey(const Key('simulated-badge')), findsOneWidget);
      expect(find.byKey(const Key('simulated-banner')), findsOneWidget);
      expect(find.text('Demo HR Strap'), findsOneWidget);

      await tick(tester, demo, 15);
      final bpm = int.parse(
        tester.widget<Text>(find.byKey(const Key('bpm'))).data!,
      );
      expect(bpm, inInclusiveRange(65, 185));
      expect(find.byKey(const Key('zone')), findsOneWidget);
      // 15 beats with RR-intervals: enough for RMSSD.
      expect(find.textContaining(' ms'), findsOneWidget);
    });

    testWidgets('demo controls take the strap off and drop the connection', (
      tester,
    ) async {
      await useSize(tester, const Size(420, 2400));
      final demo = await startDemo(tester);
      await tick(tester, demo);

      await tester.ensureVisible(find.byKey(const Key('demo-contact')));
      await tester.tap(find.byKey(const Key('demo-contact')));
      await tick(tester, demo);
      expect(find.byKey(const Key('contact-warning')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('demo-contact')));
      await tester.tap(find.byKey(const Key('demo-contact')));
      await tick(tester, demo);
      expect(find.byKey(const Key('contact-warning')), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('demo-drop')));
      await tester.tap(find.byKey(const Key('demo-drop')));
      await tester.pump();
      expect(find.byKey(const Key('status-reconnecting')), findsOneWidget);
      await tester.pump(reconnectDelays.first);
      expect(find.byKey(const Key('status-connected')), findsOneWidget);
    });

    testWidgets('records, saves, exports and deletes a session', (
      tester,
    ) async {
      await useSize(tester, const Size(420, 2400));
      final fileSaver = FakeFileSaver();
      final demo = await startDemo(tester, fileSaver: fileSaver);

      await tester.ensureVisible(find.byKey(const Key('record')));
      await tester.tap(find.byKey(const Key('record')));
      await tick(tester, demo, 30);
      expect(find.text('Recording 0:30'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('stop')));
      await tester.tap(find.byKey(const Key('stop')));
      await tester.pump();
      expect(find.text('Session saved'), findsOneWidget);

      await tester.tap(find.text('Sessions'));
      await tester.pump();
      expect(find.textContaining('0:30 · avg'), findsOneWidget);

      // Let the "Session saved" snack bar time out.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('0:30 · avg'));
      await tester.pumpAndSettle();
      expect(find.text('Sensor: Demo HR Strap'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('export-csv')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const Key('export-csv')));
      await tester.pump();
      final csv = fileSaver.saved.single;
      expect(csv.fileName, endsWith('.csv'));
      expect(csv.mimeType, 'text/csv');
      expect(csv.contents.trim().split('\r\n'), hasLength(31));

      await tester.tap(find.byKey(const Key('export-tcx')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('export-tcx-running')));
      await tester.pumpAndSettle();
      final tcx = fileSaver.saved.last;
      expect(tcx.fileName, endsWith('.tcx'));
      expect(tcx.contents, contains('<Activity Sport="Running">'));
      expect('<Trackpoint>'.allMatches(tcx.contents), hasLength(30));

      await tester.tap(find.byKey(const Key('delete-session')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-delete')));
      await tester.pumpAndSettle();
      expect(find.text('No sessions yet'), findsOneWidget);
    });
  });

  testWidgets('zone settings use age or a measured max HR', (tester) async {
    await tester.pumpWidget(await testApp(bluetooth: FakeConnector()));
    await tester.tap(find.byKey(const Key('zone-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Max HR 185 bpm'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('age-field')), '50');
    await tester.pump();
    expect(find.text('Max HR 170 bpm'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('max-hr-field')), '300');
    await tester.tap(find.byKey(const Key('save-zones')));
    await tester.pump();
    expect(find.text('Enter 100–230 bpm, or leave it empty'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('max-hr-field')), '182');
    await tester.tap(find.byKey(const Key('save-zones')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.byKey(const Key('zone-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Max HR 182 bpm'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wormhole/l10n/app_localizations.dart';
import 'package:wormhole/pages/receive_page.dart';
import 'package:wormhole/pages/transfer_widgets/transfer_finished.dart';
import 'package:wormhole/transfer/transfer_provider.dart';

void main() {
  late TransferProvider transfer;
  late List<String> received;
  String? clipboard;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    transfer = TransferProvider();
    received = [];
    transfer.addOnReceiveListener(received.add);
    clipboard = null;
  });

  Future<void> pumpApp(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return clipboard == null ? null : {'text': clipboard};
      }
      return null;
    });
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: transfer,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: home),
      ),
    ));
    await tester.pumpAndSettle();
  }

  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  Future<void> resumeApp(WidgetTester tester) async {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
  }

  group('a code on the clipboard', () {
    testWidgets('is filled in and received', (tester) async {
      clipboard = '7-guitarist-revenge';
      await pumpApp(tester, const ReceivePage());

      expect(fieldText(tester), '7-guitarist-revenge');
      expect(received, ['7-guitarist-revenge']);
    });

    testWidgets('is received without whitespace around it', (tester) async {
      clipboard = ' 7-guitarist-revenge\n';
      await pumpApp(tester, const ReceivePage());

      expect(received, ['7-guitarist-revenge']);
    });

    testWidgets('is only received once the receive tab is shown',
        (tester) async {
      clipboard = '7-guitarist-revenge';
      await pumpApp(
          tester,
          const IndexedStack(
              index: 0, children: [Text('send tab'), ReceivePage()]));
      expect(received, isEmpty);

      await pumpApp(
          tester,
          const IndexedStack(
              index: 1, children: [Text('send tab'), ReceivePage()]));
      expect(received, ['7-guitarist-revenge']);
    });

    testWidgets('is received when the app comes back', (tester) async {
      await pumpApp(tester, const ReceivePage());
      expect(received, isEmpty);

      clipboard = '7-guitarist-revenge';
      await resumeApp(tester);

      expect(received, ['7-guitarist-revenge']);
    });

    testWidgets('does not replace a typed code', (tester) async {
      await pumpApp(tester, const ReceivePage());
      await tester.enterText(find.byType(TextField), '8-');

      clipboard = '7-guitarist-revenge';
      await resumeApp(tester);

      expect(fieldText(tester), '8-');
      expect(received, isEmpty);
    });

    testWidgets('is not received a second time', (tester) async {
      clipboard = '7-guitarist-revenge';
      await pumpApp(tester, const ReceivePage());
      transfer.receiveAnother();
      await resumeApp(tester);

      expect(received, ['7-guitarist-revenge']);
    });

    testWidgets('is not received again after the app restarted',
        (tester) async {
      clipboard = '7-guitarist-revenge';
      await pumpApp(tester, const ReceivePage());
      await tester.pumpWidget(const SizedBox());

      await pumpApp(tester, const ReceivePage());

      expect(fieldText(tester), isEmpty);
      expect(received, ['7-guitarist-revenge']);
    });

    testWidgets('is not received if it was typed and received before',
        (tester) async {
      await pumpApp(tester, const ReceivePage());
      await tester.enterText(find.byType(TextField), '7-guitarist-revenge');
      await tester.tap(find.byType(FilledButton));
      transfer.receiveAnother();

      clipboard = '7-guitarist-revenge';
      await resumeApp(tester);

      expect(received, ['7-guitarist-revenge']);
    });
  });

  group('clipboard text that is no code', () {
    for (final text in [
      'see you at 7',
      '7-guitarist',
      '7-guitarist-hello',
      'wormhole receive 7-guitarist-revenge',
    ]) {
      testWidgets('is ignored: "$text"', (tester) async {
        clipboard = text;
        await pumpApp(tester, const ReceivePage());

        expect(fieldText(tester), isEmpty);
        expect(received, isEmpty);
      });
    }
  });

  group('Receive another file', () {
    Future<void> finishReceive(WidgetTester tester) async {
      Navigator.of(tester.element(find.byType(ReceivePage))).push(
          MaterialPageRoute<void>(
              builder: (_) =>
                  const Scaffold(body: ReceiveFinished(file: '/tmp/x'))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Receive another file'));
      await tester.pumpAndSettle();
    }

    testWidgets('receives a new code from the clipboard', (tester) async {
      clipboard = '7-guitarist-revenge';
      await pumpApp(tester, const ReceivePage());

      clipboard = '8-aardvark-adroitness';
      await finishReceive(tester);

      expect(fieldText(tester), '8-aardvark-adroitness');
      expect(received, ['7-guitarist-revenge', '8-aardvark-adroitness']);
    });

    testWidgets('does not receive the same code again', (tester) async {
      clipboard = '7-guitarist-revenge';
      await pumpApp(tester, const ReceivePage());

      await finishReceive(tester);

      expect(fieldText(tester), isEmpty);
      expect(received, ['7-guitarist-revenge']);
    });
  });
}

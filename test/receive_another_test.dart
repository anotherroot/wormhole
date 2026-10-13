import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wormhole/l10n/app_localizations.dart';
import 'package:wormhole/pages/receive_page.dart';
import 'package:wormhole/pages/transfer_widgets/transfer_finished.dart';
import 'package:wormhole/transfer/transfer_provider.dart';

void main() {
  testWidgets('Receive another file clears the code', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final transfer = TransferProvider();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: transfer,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ReceivePage()),
      ),
    ));
    await tester.enterText(find.byType(TextField), '7-guitarist-revenge');

    Navigator.of(tester.element(find.byType(ReceivePage))).push(
        MaterialPageRoute<void>(
            builder: (_) =>
                const Scaffold(body: ReceiveFinished(file: '/tmp/x'))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Receive another file'));
    await tester.pumpAndSettle();

    expect(find.byType(ReceivePage), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
  });
}

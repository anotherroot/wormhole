import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
import '../transfer/transfer_provider.dart';
import '../utils/code.dart';
import '../widgets/icon_text_button.dart';

class ReceivePage extends StatefulWidget {
  const ReceivePage({super.key});

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> with WidgetsBindingObserver {
  TextEditingController controller = TextEditingController();
  String? errorText;
  late final TransferProvider _transfer;

  /// Whether this page is in front: its tab is selected and no transfer page
  /// is pushed on top of it.
  bool _shown = false;

  _ReceivePageState() {
    controller.addListener(() {
      setState(() {
        errorText = null;
      });

      // Replace spaces with dashes
      if (controller.text.endsWith(' ')) {
        controller.text =
            '${controller.text.substring(0, controller.text.length - 1)}-';
        controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _transfer = Provider.of<TransferProvider>(context, listen: false);
    _transfer.addOnReceiveAnotherListener(controller.clear);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shown =
        Visibility.of(context) && (ModalRoute.of(context)?.isCurrent ?? true);
    if (shown && !_shown) {
      _receiveCodeFromClipboard();
    }
    _shown = shown;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _shown) {
      _receiveCodeFromClipboard();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transfer.removeOnReceiveAnotherListener(controller.clear);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.download,
              size: 96,
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              AppLocalizations.of(context)!.receive_page_label,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(
              height: 5,
            ),
            Text(AppLocalizations.of(context)!.receive_page_sublabel),
            const SizedBox(
              height: 25,
            ),
            SizedBox(
              width: 250,
              child: TextField(
                controller: controller,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+.*')),
                ],
                cursorColor: theme.colorScheme.onPrimary,
                decoration: InputDecoration(
                  filled: true,
                  errorText: errorText,
                  focusedBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      borderSide: BorderSide(
                          color: theme.colorScheme.secondary, width: 2)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      borderSide: BorderSide(
                          color: theme.colorScheme.primary, width: 2)),
                  border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15))),
                  hintText:
                      AppLocalizations.of(context)!.receive_page_textfield_hint,
                ),
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            IconTextButton(
                onClick: _onReceiveButtonClick,
                text: AppLocalizations.of(context)!.receive_page_button,
                icon: Icons.archive),
          ],
        ),
      ),
    );
  }

  void _onReceiveButtonClick() async {
    final text = controller.value.text;

    if (!isCodeValid(text) || !mounted) {
      setState(() {
        errorText = 'Invalid Code';
      });
      return;
    }

    Settings.setLastReceiveCode(text);
    Provider.of<TransferProvider>(context, listen: false).receiveFile(text);
  }

  /// Receive a code someone copied to send it here, like the code of the sender.
  /// Only into an empty field, and not the code of the last receive, which is
  /// often still on the clipboard.
  Future<void> _receiveCodeFromClipboard() async {
    if (controller.text.isNotEmpty) return;
    final code = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (code == null ||
        !isWordlistCode(code) ||
        code == await Settings.getLastReceiveCode() ||
        !mounted ||
        !_shown ||
        controller.text.isNotEmpty) {
      return;
    }
    controller.text = code;
    _onReceiveButtonClick();
  }
}

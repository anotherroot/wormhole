import 'package:flutter/cupertino.dart';

class TransferProvider with ChangeNotifier {
  final List<Function(String name, List<String> paths)> _sendHandlers = [];
  final List<Function(String name, String path)> _sendFolderHandlers = [];
  final List<void Function(String text)> _sendTextHandlers = [];
  final List<void Function(String passphrase)> _receiveHandlers = [];
  final List<void Function()> _receiveAnotherHandlers = [];

  TransferProvider();

  void addOnSendListener(
      void Function(String name, List<String> paths) listener) {
    _sendHandlers.add(listener);
  }

  void addOnSendFolderListener(
      void Function(String name, String path) listener) {
    _sendFolderHandlers.add(listener);
  }

  void addOnSendTextListener(void Function(String text) listener) {
    _sendTextHandlers.add(listener);
  }

  void addOnReceiveListener(void Function(String passphrase) listener) {
    _receiveHandlers.add(listener);
  }

  void addOnReceiveAnotherListener(void Function() listener) {
    _receiveAnotherHandlers.add(listener);
  }

  void removeOnReceiveAnotherListener(void Function() listener) {
    _receiveAnotherHandlers.remove(listener);
  }

  void sendFiles(String name, List<String> paths) {
    for (final h in _sendHandlers) {
      h(name, paths);
    }
  }

  void sendFolder(String name, String path) {
    for (final h in _sendFolderHandlers) {
      h(name, path);
    }
  }

  void sendText(String text) {
    for (final h in _sendTextHandlers) {
      h(text);
    }
  }

  void receiveFile(String passphrase) {
    for (final h in _receiveHandlers) {
      h(passphrase);
    }
  }

  /// A receive finished and the user wants to receive another file.
  void receiveAnother() {
    for (final h in _receiveAnotherHandlers) {
      h();
    }
  }
}

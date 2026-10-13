import 'pgp_words.dart';

// regex to match code validity
final RegExp _regex = RegExp(r'^\d+-[^\s]*$');

/// Demo code for App Store review (simulates file transfer without server)
const String demoCode =
    '999763-demoooooo-mode-transfer-that-should-never-collide';

/// Check if the provided code is the demo code
bool isDemoCode(String code) {
  return code == demoCode;
}

/// validate syntax of correction code
bool isCodeValid(String code) {
  return _regex.hasMatch(code);
}

/// Extract a valid receive code from a Wormhole transfer deep link.
///
/// Other URL schemes are used internally on iOS (for example, the share
/// extension's `ShareMedia-…` handoff) and must not enter the receive flow.
String? passphraseFromTransferUri(Uri uri) {
  if (uri.scheme != 'wormhole-transfer' || !isCodeValid(uri.path)) {
    return null;
  }
  return uri.path;
}

/// Whether [text] is exactly a code as wormhole clients make them: a number
/// and two or more words of the word list, like `7-guitarist-revenge`.
bool isWordlistCode(String text) {
  final parts = text.split('-');
  return parts.length >= 3 &&
      RegExp(r'^\d+$').hasMatch(parts.first) &&
      parts.skip(1).every(pgpWords.contains);
}

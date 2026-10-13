import 'package:flutter_test/flutter_test.dart';
import 'package:wormhole/utils/code.dart';

void main() {
  group('isWordlistCode', () {
    test('a number and two words of the word list', () {
      expect(isWordlistCode('7-guitarist-revenge'), isTrue);
      expect(isWordlistCode('1234-aardvark-adroitness'), isTrue);
    });

    test('more words, as made with a longer code length', () {
      expect(isWordlistCode('7-guitarist-revenge-aardvark'), isTrue);
    });

    test('not just one word', () {
      expect(isWordlistCode('7-guitarist'), isFalse);
    });

    test('not words outside the word list', () {
      expect(isWordlistCode('7-guitarist-hello'), isFalse);
      expect(isWordlistCode('7-Guitarist-revenge'), isFalse);
    });

    test('not without the number', () {
      expect(isWordlistCode('guitarist-revenge'), isFalse);
      expect(isWordlistCode('x-guitarist-revenge'), isFalse);
    });

    test('not with anything around it', () {
      expect(isWordlistCode('7-guitarist-revenge '), isFalse);
      expect(isWordlistCode('7-guitarist-revenge-'), isFalse);
      expect(isWordlistCode('code: 7-guitarist-revenge'), isFalse);
      expect(isWordlistCode(''), isFalse);
    });
  });
}

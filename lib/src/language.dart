part of lexer;

Language reject = const Reject();
Language match = const Match();

/// End of input special object.
var EOI = const EndOfInput();

abstract class Language {
  const Language();
  bool get isMatchable => false;
  Language derive(dynamic ch);
}


/// A [Language] that rejects everything.
class Reject extends Language {
  const Reject();
  Language derive(dynamic ch) => reject;
  toString() => '{}';
}


/// A [Language] that matches the defined [Language].
class Match extends Language {
  const Match();
  bool get isMatchable => true;
  Language derive(dynamic ch) => reject;
  toString() => '\'\'';
}


/// A special [Language] that matches the end of input.
/// This [Language] is used as the last derivative to test wheather it is a
/// match.
class EndOfInput extends Language {
  const EndOfInput();
  Language derive(dynamic ch) => (ch == EOI)? match: reject;
  toString() => '<EOI>';
}


/// A [Language] that matches a specific character.
class Character extends Language {
  final String ch;
  Character(this.ch);
  Language derive(dynamic c) => (ch == c) ? match : reject;
  toString() => '$ch';
}


/// A [Language] that matches either of two [Language]s.
class Or extends Language {
  final Language left;
  final Language right;

  bool get isMatchable => left.isMatchable || right.isMatchable;

  Or._internal(this.left, this.right);
  factory Or(left, right) => throw "Not permitted. Use makeOr instead";
  Language derive (String c) {
    return makeOr(left.derive(c), right.derive(c));
  }
  toString() => '$left|$right';
}

/// A [Language] that matches two [Language]s in sequence.
class And extends Language {
  final Language left;
  final Language right;

  bool get isMatchable => left.isMatchable && right.isMatchable;

  And._internal(this.left, this.right);
  factory And(left, right) => throw "Not permitted. Use makeAnd instead";

  Language derive (String c) {

    // TODO(Sam): It looks like we need this only for Star.. Is this true?
    if(left.isMatchable){
      return makeOr(makeAnd(left.derive(c), right), right.derive(c));
    }
    return makeAnd(left.derive(c), right);
  }
  toString() => "$left$right";
}


/// A [Language] that matches the kleene star of a [Language].
class Star extends Language {
  final Language language;

  bool get isMatchable => true;

  Star._internal(this.language);
  factory Star(language) => throw "Not permitted. Use makeStar instead";

  Language derive(ch) => makeAnd(language.derive(ch), makeStar(language));
  toString() => '$language*';
}

/// A [Language] that matches zero or one of a [Language].
class Optional extends Language {
  final Language language;

  bool get isMatchable => true;

  Optional._internal(this.language);
  factory Optional(language) => throw "Not permitted. Use makeOptional instead";

  Language derive(ch) => language.derive(ch);
  toString() => '($language)?';
}


/// Helper [Language] represents a letter [a..z] [A..Z].
class Letter extends Language {
  const Letter();
  Language derive(dynamic c) {
    if(c is! String) return reject;
    if(a_z(c) || A_Z(c))
      return match;
    return reject;
  }
  bool a_z(String c) => c.codeUnitAt(0) >= 'a'.codeUnitAt(0) &&
                        c.codeUnitAt(0) <= 'z'.codeUnitAt(0);

  bool A_Z(String c) => c.codeUnitAt(0) >= 'A'.codeUnitAt(0) &&
                        c.codeUnitAt(0) <= 'Z'.codeUnitAt(0);
  toString() => '<LETTER>';
}

/// Helper [Language] represents a digit 0..9.
class Digit extends Language {
  const Digit();
  Language derive(dynamic c) {
    if(c is! String) return reject;
    if(digit(c))
      return match;
    return reject;
  }
  bool digit(String c) => c.codeUnitAt(0) >= '0'.codeUnitAt(0) &&
                          c.codeUnitAt(0) <= '9'.codeUnitAt(0);
  toString() => '<DIGIT>';
}

/// Helper [Language] represents a hex digit 0..9 A..F a..f.
class HexDigit extends Language {
  const HexDigit();
  Language derive(dynamic c) {
    if(c is! String) return reject;
    if(isBetween(c, '0', '9') ||
       isBetween(c, 'a', 'f') ||
       isBetween(c, 'A', 'F')) {
       return match;
     }
    return reject;
  }
  bool isBetween(String c, String from, String to) =>
      c.codeUnitAt(0) >= from.codeUnitAt(0) &&
      c.codeUnitAt(0) <= to.codeUnitAt(0);
  toString() => '<HEX_DIGIT>';
}


/// Helper [Language] represents a newline character.
class Newline extends Language {
  const Newline();
  Language derive(dynamic c) {
    if(c is! String) return reject;
    if(c == '\r' || c == '\n')
      return match;
    return reject;
  }
  toString() => '<NEWLINE>';
}

/// Helper [Language] represents a not character.
class NotCharacter extends Character {
  NotCharacter(ch):super(ch);
  Language derive(dynamic c) => (ch == c) ? reject : match;
  toString() => '~<$ch>';
}

/// Helper [Language] represents the revese of another [Language].
class Not extends Language {
  final Language language;
  Not(this.language);
  Language derive(dynamic c) {
    var d = language.derive(c);
    if(d == match) return reject;
    else if(d == reject) return match;
    return new Not(d);
  }
  toString() => '~{$language}';
}

/// Helper factory functions.
/// (sam): moved them out of factory constructors because checked mode
/// complained that they don't return the same type.
Language makeOr(Language left, Language right){
  if (left == reject && right == reject) return reject;
  if (left == reject) return right;
  if (right == reject) return left;
  if (left == match || right == match) return match;
  return new Or._internal(left, right);
}

Language makeAnd(Language left, Language right){
  if(left == match) return right;
  //if(right == match) return left; // Really? does this make sense?
  if(left == reject || right == reject) return reject;
  return new And._internal(left, right);
}

Language makeStar(Language language){
  if(language == match) return match;
  if(language == reject) return reject;
  return new Star._internal(language);
}

Language makeOptional(Language language){
  if(language == match) return match;
  if(language == reject) return reject;
  return new Optional._internal(language);
}

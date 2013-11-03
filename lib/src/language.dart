part of lexer;

Language reject = new Reject();
Language match = new Match();

/// End of input special object.
var EOI = new EndOfInput();

abstract class Language {
  bool get isMatchable => false;
  Language derive(dynamic ch);
}


/// A [Language] that rejects everything.
class Reject extends Language {
  Language derive(dynamic ch) => reject;
  toString() => '{}';
}


/// A [Language] that matches the defined [Language].
class Match extends Language {
  bool get isMatchable => true;
  Language derive(dynamic ch) => reject;
  toString() => '\'\'';
}


/// A special [Language] that matches the end of input.
/// This [Language] is used as the last derivative to test wheather it is a
/// match.
class EndOfInput extends Language {
  Language derive(dynamic ch) => reject;//(ch == EOI)? match: reject;
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
  factory Or(left, right){
    if (left == reject && right == reject) return reject;
    if (left == reject) return right;
    if (right == reject) return left;
    if (left == match || right == match) return match;
    return new Or._internal(left, right);
  }
  Language derive (String c) {
    return new Or(left.derive(c), right.derive(c));
  }
  toString() => '$left|$right';
}

/// A [Language] that matches two [Language]s in sequence.
class And extends Language {
  final Language left;
  final Language right;

  bool get isMatchable => left.isMatchable && right.isMatchable;

  And._internal(this.left, this.right);

  factory And(left, right){
    if(left == match) return right;
    //if(right == match) return left; // Really? does this make sense?
    if(left == reject || right == reject) return reject;
    return new And._internal(left, right);
  }

  Language derive (String c) {

    // TODO(Sam): It looks like we need this only for Star.. Is this true?
    if(left.isMatchable){
      return new Or(new And(left.derive(c), right), right.derive(c));
    }
    return new And(left.derive(c), right);
  }
  toString() => '$left$right';
}


/// A [Language] that matches the kleene star of a [Language].
class Star extends Language {
  final Language language;

  bool get isMatchable => true;

  Star._internal(this.language);
  factory Star(language){
    if(language == match) return match;
    if(language == reject) return reject;
    return new Star._internal(language);
  }
  Language derive(ch) => new And(language.derive(ch), new Star(language));
  toString() => '$language*';
}


/// Helper [Language] represents a letter [a..z] [A..Z]
class Letter extends Character {
  Language derive(dynamic c) {
    if(c is! String) return empty;
    if(a_z(c) || A_Z(c))
      return match;
    return empty;
  }
  bool a_z(String c) => c.codeUnitAt(0) >= 'a'.codeUnitAt(0) &&
                        c.codeUnitAt(0) <= 'z'.codeUnitAt(0);

  bool A_Z(String c) => c.codeUnitAt(0) >= 'A'.codeUnitAt(0) &&
                        c.codeUnitAt(0) <= 'Z'.codeUnitAt(0);
}

/// Helper [Language] represents a digit 0..9
class Digit extends Character {
  Language derive(dynamic c) {
    if(c is! String) return empty;
    if(digit(c))
      return match;
    return empty;
  }
  bool digit(String c) => c.codeUnitAt(0) >= '0'.codeUnitAt(0) &&
                          c.codeUnitAt(0) <= '9'.codeUnitAt(0);
}

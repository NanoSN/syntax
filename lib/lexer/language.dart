Language empty = new Empty();
Language match = new Match();

/// End of input special object.
var EOI = new EndOfInput();

abstract class Language {
  Language derive(dynamic ch);
}


/// A [Language] that rejects everything.
class Empty extends Language {
  Language derive(dynamic ch) => empty;
  toString() => '{}';
}


/// A [Language] that matches the defined [Language].
class Match extends Language {
  Language derive(dynamic ch) => empty;
  toString() => '\'\'';
}


/// A special [Language] that matches the end of input.
/// This [Language] is used as the last derivative to test wheather it is a
/// match.
class EndOfInput extends Language {
  Language derive(dynamic ch) => (ch == EOI)? match: empty;
  toString() => '<EOI>';
}


/// A [Language] that matches a specific character.
class Character extends Language {
  final String ch;
  Character(this.ch);
  Language derive(dynamic c) => (ch == c) ? match : empty;
  toString() => '$ch';
}


/// A [Language] that matches either of two [Language]s.
class Or extends Language {
  final Language left;
  final Language right;
  Or._internal(this.left, this.right);
  factory Or(left, right){
    if (left == empty && right == empty) return empty;
    if (left == empty) return right;
    if (right == empty) return left;
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
  And._internal(this.left, this.right);

  factory And(left, right){
    if(left == match) return right;
    //if(right == match) return left; // Really? does this make sense?
    if(left == empty || right == empty) return empty;
    return new And._internal(left, right);
  }

  Language derive (String c) {

    // TODO(Sam): It looks like we need this only for Star.. Is this true?
    if(left is Star){
      return new Or(new And(left.derive(c), right), right.derive(c));
    }
    return new And(left.derive(c), right);
  }
  toString() => '($left$right)';
}


/// A [Language] that matches the kleene star of a [Language].
class Star extends Language {
  final Language language;
  Star._internal(this.language);
  factory Star(language){
    if(language == match) return match;
    if(language == empty) return empty;
    return new Star._internal(language);
  }
  Language derive(ch) => new And(language.derive(ch), new Star(language));
  toString() => '$language*';
}

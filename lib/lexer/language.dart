Language empty = new Empty();
Language match = new Match();

abstract class Language {
  Language derive(String ch);
}


///A regular expression that matches no strings at all (null?).
class Empty extends Language {
  Language derive(String ch) => empty;
  toString() => '{}';
}


///A regular expression that matches the empty string
/// TODO: Can I call it the Match Language?!
class Match extends Language {
  Language derive(String ch) => empty;
  toString() => '\'\'';
}


///A regular expression that matches a specific character.
class Character extends Language {
  final String ch;
  Character(this.ch);
  Language derive(String c) => (ch == c) ? match : empty;
  toString() => '$ch';
}


///A regular expression that matches either of two regular expressions.
class Or extends Language {
  final Language left;
  final Language right;
  Or(this.left, this.right);
  Language derive (String c) {
    if (left == empty && right == empty){
      return empty;
    }

    if (left == match || right == match){
      return match;
    }

    var dl = left.derive(c);
    var dr = right.derive(c);

    if (dl == empty && dr == empty){
      return empty;
    }

    if (dl == match || dr == match){
      return match;
    }
    return new Or(dl, dr);
  }
  toString() => '$left|$right';
}

///A regular expression that matches two regular expression in sequence.
class And extends Language {
  final Language left;
  final Language right;
  And(this.left, this.right);

  Language derive (String c) {
    if(left == empty || right == empty){
      return empty;
    }

    if(left == match && right == match){
      return match;
    }
    var dl = left.derive(c);
    var dr = right.derive(c);

    if(left == match && dr == match){
      return match;
    }
    if(left == match && dr == empty){
      return empty;
    }
    if(left == match){
      return new Or(new And(dl, right), dr);
    }
    return new And(left.derive(c), right);
  }
  toString() => '($left$right)';
}

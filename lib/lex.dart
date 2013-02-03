library lex;

abstract class Language {
  bool get acceptsEmptyString;
  bool get rejectsAll;
  bool get isEmptyString;
  Language derive(String ch);
  Language deriveEND() => new EmptySet();
  bool mustBeSubsumedBy(Language other) => false;

  /// represents 'a?'
  Language zeroOrOne() {
    if (isEmptyString) return this;
    if (rejectsAll) return new Epsilon();
    return new Union(new Epsilon(), this);
  }

  /// return one or more repetitions of this regular expression.
  ///represents 'a+'
  Language oneOrMore() {
    if (isEmptyString) return this;
    if (rejectsAll) return new EmptySet();
    return new Catenation(this, new Star(this));
  }

  /// return zero or more repetitions of this regular expression. (Kleene star.)
  ///represents 'a*'
  Language zeroOrMore() {
    if (this.isEmptyString) return this;
    if (this.rejectsAll) return new Epsilon();
    return new Star(this);
  }

  ///represents 'a{4}' n=4
  Language exactlyNtimes(int n) {
    if (n <  0) return new EmptySet();
    if (n == 0) return new Epsilon();
    if (n == 1) return this;
    if (this.isEmptyString) return new Epsilon();
    if (this.rejectsAll)    return new EmptySet();
    return new Repetition(this, n);
  }

  ///return the smart concatenation of this and another regular expression.
  Language and(Language suffix) {
    if (this.isEmptyString) return suffix;
    if (suffix.isEmptyString) return this;
    if (this.rejectsAll) return new EmptySet();
    if (suffix.rejectsAll) return new EmptySet();
    return new Catenation(this, suffix);
  }

  ///return the smart union of this and another regular expression.
  Language or (Language choice2) {
    if (this.rejectsAll) return choice2;
    if (choice2.rejectsAll) return this;
    if (this.mustBeSubsumedBy(choice2)) return choice2;
    if (choice2.mustBeSubsumedBy(this)) return this;
    return new Union(this, choice2);
  }
  Rule rule (action) {
    return new Rule(this, action);
  }

  Language operator |(Language choice2) => or(choice2);
  Language operator +(Language suffix) => and(suffix);
  Language operator *(Language NULL) => zeroOrMore();
  Rule operator <=(action) => rule(action);
}

///A regular expression that matches the end of the input.
class END extends Language {
  Language derive(String ch) => new EmptySet();
  Language deriveEND() => new Epsilon();
  bool get acceptsEmptyString => false;
  bool get rejectsAll => false;
  bool get isEmptyString => false;
  toString() => '\$';
}

///A regular expression that matches no strings at all.
class EmptySet extends Language {
  Language derive(String ch) => this;
  bool get acceptsEmptyString => false;
  bool get rejectsAll => true;
  bool get isEmptyString => false;
  toString() => '{}';
}

///A regular expression that matches the empty string.
class Epsilon extends Language {
  Language derive(String ch) => new EmptySet();
  bool get acceptsEmptyString => true;
  bool get rejectsAll => false;
  bool get isEmptyString => true;
  toString() => "''";
}

///A regular expression that matches any character.
class AnyChar extends Language {
  Language derive(String c) => new Epsilon();
  get acceptsEmptyString => false;
  get rejectsAll => false;
  get isEmptyString => false;
  toString() => '.';
}

///A regular expression that matches a specific character.
class Character extends Language {
  final String ch;
  Character(this.ch);
  Language derive(String c) => (ch == c) ? new Epsilon() : new EmptySet();
  bool get acceptsEmptyString => false;
  bool get rejectsAll => false;
  bool get isEmptyString => false;

  bool mustBeSubsumedBy(dynamic other) {
    if (other is Character) return ch == other.ch;
    return (other is AnyChar);
  }
  toString() => ch;
}

///A regular expression that matches a set of characters.
class CharSet extends Language {
  ///dont care about doublicates.. logic should work just fine
  String set;
  CharSet(this.set);

  Language derive (String c) {
    if(set.contains(c)) return new Epsilon();
    return new EmptySet();
  }

  get acceptsEmptyString => false;
  get rejectsAll => set.isEmpty;
  get isEmptyString => false;
  toString() => '[$set]';
}

/// A regular expression that matches anything not in a set of characters.
class NotCharSet extends Language {
  String set;
  NotCharSet(this.set);

  Language derive (String c) {
    if(set.contains(c)) return new EmptySet();
    return new Epsilon();
  }

  get acceptsEmptyString => false;
  get rejectsAll => set.length == 100713; //all chars (unicode)
  get isEmptyString => false;
  toString() => '[^$set]';
}

///A regular expression that matches two regular expression in sequence.
class Catenation extends Language {
  Language left;
  Language right;
  Catenation(this.left, this.right);

  Language derive (String c) {
    if (left.acceptsEmptyString)
      return new Union(new Catenation(left.derive(c), right), right.derive(c));
    else
      return new Catenation(left.derive(c), right);
  }

  get acceptsEmptyString => left.acceptsEmptyString && right.acceptsEmptyString;
  get rejectsAll => left.rejectsAll || right.rejectsAll;
  get isEmptyString => left.isEmptyString && right.isEmptyString;

  toString() => '($left$right)';
}

///A regular expression that matches either of two regular expressions.
class Union extends Language {
  Language left;
  Language right;
  Union(this.left, this.right);

  Language derive (String c) {
    return new Union(left.derive(c), right.derive(c));
  }

  get acceptsEmptyString => left.acceptsEmptyString || right.acceptsEmptyString;
  get rejectsAll => left.rejectsAll && right.rejectsAll;
  get isEmptyString => left.isEmptyString && right.isEmptyString;
  toString() => '($left|$right)';
}

/// A regular expression that matches zero or more repetitions of a regular
/// expression.
class Star extends Language {
  Language left;
  Star(this.left);

  Language derive (String c) {
    return new Catenation(left.derive(c), new Star(left));
  }

  get acceptsEmptyString => true;
  get rejectsAll => false;
  get isEmptyString => left.isEmptyString || left.isEmptyString; //TODO? is this true?

  // TODO: this might get me in truble if left is Star
  toString() => '$left*';
}

/// A regular expression that matches exactly n repetitions a regular expression.
class Repetition extends Language {
  Language left;
  int n;
  Repetition(this.left, this.n);

  Language derive (String c) {
    if (n <= 0) return new Epsilon();
    //return left.derive(c) ~ (left ^ (n-1));
    return new Catenation(left.derive(c), new Repetition(left, n-1));
  }

  get acceptsEmptyString => (n == 0) || ((n > 0) && left.acceptsEmptyString);
  get rejectsAll => (n < 0) || left.rejectsAll;
  get isEmptyString => (n == 0) || ((n > 0) && left.isEmptyString);
  toString() => '$left{$n}';
}


/// A lexer rule represents a regular language to match and an action
/// to fire once matched.
class LexerRule {
  Language regex;
  Function action;
  LexerRule(this.regex, this.action);
  bool get mustAccept => regex.isEmptyString;
  bool get accepts => regex.acceptsEmptyString;
  bool get rejects => regex.rejectsAll;

  LexerState fire(String chars) {
    return action(chars);
  }

  LexerRule deriveEND() => new LexerRule(regex.deriveEND(), action);
  LexerRule derive (String ch) => new LexerRule(regex.derive(ch), action);
  toString() => regex.toString();
}

/// A lexer state represents the current state of the lexer.
/// Each state contains rules to match.
abstract class LexerState {
  /// Rules for this lexing state.
  List<LexerRule> rules;

  /// Characters lexed so far in this state.
  String chars;

  /// True iff this state could accept.
  bool get isAccept => rules.any((_) => _.accepts);

  ///True iff this state accepts, but no succesor possible could.
  bool get mustAccept {
    var sawMustAccept = false;
    for (final r in rules) {
      if (r.mustAccept && !sawMustAccept)
        sawMustAccept = true;
      else if (!r.rejects)
        return false;
    }
    return sawMustAccept;
  }

  /// True iff no string can ever be matched from this state.
  bool get isReject => rules.every((_) => _.rejects);

  /// Causes the characters lexed thus far to be accepted;
  /// returns the next lexing state.
  LexerState fire () {
    var accepting = rules.where((_) => _.accepts);
    return (accepting.last).fire(chars); // reverse);
  }

  /// Checks to see if any of the rules match the end of input.
  /// return the lexer state after such a match.
  LexerState terminate () {
    return new MinorLexerState(chars,
        rules.mappedBy((_) => _.deriveEND()).where( (_) => !_.rejects));
  }

  /// Checks to see if any of the rules match the input c.
  /// return the lexer state after such a match.
  LexerState next (String c) {
    return new MinorLexerState('$c$chars',
        rules.mappedBy((_) => _.derive(c)).where( (_) => !_.rejects));
  }
}

/// A state that rejects everything.
class RejectLexerState extends LexerState {
  fire () => throw new Exception("Lexing failure at: currentInput");
  get rules => []; //Nil
  String chars = null;
  }

///   A minor lexer state is an intermediate lexing state.
class MinorLexerState extends LexerState {
  MinorLexerState(chars, rules) {
    this.chars = chars;
    this.rules = rules;
  }
}

/// A major lexing state is defined by the programmer.
class MajorLexerState extends LexerState {
  String chars = '';
  List<LexerRule> rules = new List<LexerRule>();

  /// Deletes all of the rules for this state.
  void reset () {
    rules = new List();
  }
}


/// Clean API
class CharacterRange extends CharSet {
  var from;
  var to;

  CharacterRange(this.from): super('');
  R(String c) {
    to = c;
    var r = [];
    for ( var i=from.charCodeAt(0); i<=to.charCodeAt(0); i++){
      r.add(i);
    }
    set = new String.fromCharCodes(r);
  }

  toString() => '[$from-$to]';
}

///Character range
CharacterRange R(s) => new CharacterRange(s);

///Single char
Character T(s) => new Character(s);

///Word
Language W(s) {
  Catenation cat;
  Character prev;
  s.splitChars().forEach( (_) {
    if(cat == null && prev == null) prev = T(_);
    else if(cat == null) cat = prev + T(_);
    else cat = cat + T(_);
  });
  return cat;
}

class Rule {
  Language regex;
  var action;
  Rule(this.regex, this.action);
  bool get mustAccept => regex.isEmptyString;
  bool get accepts => regex.acceptsEmptyString;
  bool get rejects => regex.rejectsAll;

  Rule derive (String ch) => new Rule(regex.derive(ch), action);
}

/// for now: simple lexer with one rule
class Lexer {
  Rule rule;
  Lexer(this.rule);
  List out = [];
  Iterator input;

  Rule _currentRule;
  Rule _lastAcceptedRule;
  String _lastAcceptedInput;

  ///contains chars that are not fully matched
  String str;

  lex(String s){
    _currentRule = rule;
    for (final c in s.splitChars()){
      _currentRule = _currentRule.derive(c);
      str = '$str$c';
      if(_currentRule.accepts) {
        _lastAcceptedRule = _currentRule;
        _lastAcceptedInput = str;
        str = '';
      } else if (_currentRule.rejects) {
        out.add(_lastAcceptedRule.action(str));
        _lastAcceptedRule = null;
        _lastAcceptedInput = null;
        _currentRule = rule;
      }
    }
  }

  lex2(String s) {
    input = s.splitChars().iterator;
    str = (input..moveNext()).current;

    _currentRule = rule;

    while(input.current != null){
      print("'$str'");
      print("'$_lastAcceptedInput'");
      _currentRule = _currentRule.derive(input.current);
      if(accepted()) {
        if(input.moveNext())
          str = str.concat(input.current);
        continue;
      }
      if(acceptsCurrentRule()) {
      }
      else if (rejectsCurrentRule()) continue;

      // If at the end of the input, clean up:
      if (input.current == null) break;


      if(input.moveNext())
        str = str.concat(input.current);
    }
  }

  bool accepted() {
    if(_currentRule.mustAccept){
      print('accepted');
      out.add(_currentRule.action(_lastAcceptedInput));
      _lastAcceptedRule = null; //Reject Rule
      _lastAcceptedInput = null;
      _currentRule = rule;
      return true;
    }
    return false;
  }

  bool acceptsCurrentRule() {
    if(_currentRule.accepts){
      print('acceptsCurrentRule $_currentRule');
      _lastAcceptedRule = _currentRule;
      _lastAcceptedInput = str;
      print("'$str'");
      str = '';
      return true;
    }
    return false;
  }

  bool rejectsCurrentRule() {
    if (_lastAcceptedRule != null && _currentRule.rejects) {
      print('rejectsCurrentRule');
      out.add(_lastAcceptedRule.action(_lastAcceptedInput));
      _lastAcceptedRule = null;
      _lastAcceptedInput = null;
      _currentRule = rule;
      return true;
    }
  }

}

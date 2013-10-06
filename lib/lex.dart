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
  Language operator +(Language suffix) {
    if (suffix == null)
      return this.oneOrMore();
    return and(suffix);
  }
  Language operator *(Language NULL) => zeroOrMore();
  Language operator %(Language NULL) => zeroOrOne();
  Rule operator <=(action) => rule(action);
}

///A regular expression that matches the end of the input.
class END extends Language {
  Language derive(String ch) => new EmptySet();
  Language deriveEND() => new Epsilon();
  bool get acceptsEmptyString => false;
  bool get rejectsAll => false;
  bool get isEmptyString => false;
  toString() => '\$\$\$';
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
  toString() => 'e';
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
  toString() => "'$ch'";
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
    var accepting = new List.from(rules.where((_) => _.accepts));
    return (accepting.last).fire(chars); // reverse);
  }

  /// Checks to see if any of the rules match the end of input.
  /// return the lexer state after such a match.
  LexerState terminate () {
    return new MinorLexerState(chars,
        new List.from(rules.mappedBy((_) => _.deriveEND()).where( (_) => !_.rejects)));
  }

  /// Checks to see if any of the rules match the input c.
  /// return the lexer state after such a match.
  LexerState next (String c) {
    return new MinorLexerState('$c$chars',
        new List.from(rules.mappedBy((_) => _.derive(c)).where( (_) => !_.rejects)));
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
  Function action;
  Rule(this.regex, this.action);
  bool get mustAccept => regex.isEmptyString;
  bool get accepts => regex.acceptsEmptyString;
  bool get rejects => regex.rejectsAll;

  Rule derive (String ch) => new Rule(regex.derive(ch), action);
  Rule deriveEND() => new Rule(regex.deriveEND(), action);
  State accept(List inputs) => action(inputs);
}

/// Represents a state
abstract class _State {

  _State(this.inputs, this.rules);

  /// Rules for this state
  List<Rule> rules;

  /// inputs matched in this state so far
  List inputs;

  /// True iff this state can accept
  bool get isAccept => rules.any((_) => _.accepts);

  /// True iff no input can ever be matched from this state.
  bool get isReject => rules.every((_) => _.rejects);

  /// True iff this state accepts, but no sucessor possible could.
  bool get mustAccept {
    var accept = false;
    for(final r in rules){
      if(r.mustAccept && !accept){
        accept = true;
      } else if(!r.rejects){
        return false;
      }
    }
    return accept;
  }

  /// Accepts the [input]
  _State accept(){
    print('accepting $inputs');
    var accepting = new List.from(rules.where((_) => _.accepts));
    return (accepting.last).accept(new List.from(inputs));
  }

  /// Checks to see if any of the rules match the end of input.
  /// returns the lexer state after such a match.
  _State terminate() =>
    new InternalState(inputs, new List.from(rules.mappedBy((_) =>
                _.deriveEND()).where((_) =>!_.rejects)));



  /// Checks to see if any of the rules match the input c.
  /// returns the lexer state after such a match.
  _State next(dynamic input) {
    var state = new InternalState( new List.from(inputs..add(input)),
        new List.from(rules.mappedBy((_) =>
                _.derive(input)).where((_) =>!_.rejects)));

    //    if(state.isReject)
    //      return new RejectState(inputs..add(input));
    return state;
  }

  _State operator >>(Rule rule) => this..rules.add(rule);
}

class InternalState extends _State {
  InternalState(inputs, rules): super(inputs, rules);
}

class RejectState extends _State {
  RejectState(inputs): super(inputs, []);
  accept() => throw new Exception("Lexing failure at: $inputs");
}

/// State to be defined by the user.
class State extends _State {

  List<Rule> _rules = <Rule>[];

  /// Starts with empty rules and input
  State(): super([], []);

  void reset () {
    _rules = <Rule>[];
  }

  //TODO: API for adding rules
}

class StatefullState extends State {}
class Lexer {
  /// During lexing, the last encountered which accepted.
  _State lastAcceptingState = new State();

  /// During lexing, the input associated with the last accepting state.
  List lastAcceptingInput;

  /// During lexing, the current lexer state.
  _State currentState;

  /// During lexing, the location in the current input.
  List currentInput;

  /// output tokens
  List output = [];

  /// hidden tokens
  List _hidden = [];

  var main = new State();

  /// Starts the lexer on the given input stream.
  /// The field output will contain a live stream of the lexer output.
  void lex (input) {
    currentState = main;
    currentInput = input.splitChars(); //TODO: check type
    work();
  }

  void work(){
    while (workStep()) {
      print('\n');
    };
  }

  bool workStep() {
    print('mainInputs: ${main.inputs}');    
    print('inputs: ${currentState.inputs}');
    print('currentInput: $currentInput');
    print('lastAcceptingState:${lastAcceptingState.inputs}');
    print('lastAcceptingInput:${lastAcceptingInput}');

    // First, check to see if the current state must accept.
    if (currentState.mustAccept) {
      print('mustAccept');
      currentState = currentState.accept();
      lastAcceptingState = new RejectState(new List.from(currentState.inputs));
      lastAcceptingInput = null;
      return true;
    }

    // First, check to see if the curret state accepts or rejects.
    if (currentState.isAccept) {
      print('isAccept');
      var rs = new List.from(currentState.rules);
      var ins = new List.from(currentState.inputs);
      lastAcceptingState = new InternalState(ins,rs);
      lastAcceptingInput = new List.from(currentInput);
      
    } else if (currentState.isReject) {
      print('isReject');
      // Backtrack to the last accepting state; fail if none.
      currentState = lastAcceptingState.accept();
      currentInput = new List.from(lastAcceptingInput);
      lastAcceptingState = new RejectState(new List.from(currentState.inputs));
      lastAcceptingInput = null;
      print('isRejectInput: ${currentState.inputs}');
      return true;
    }

    // If at the end of the input, clean up:
    if (currentInput.isEmpty) {
      print('isEmpty');
      var terminalState = currentState.terminate();
      if (terminalState.isAccept) {
        terminalState.accept();
        return false;
      } else {
      print('not isEmpty');
        currentState = lastAcceptingState.accept();
        currentInput = lastAcceptingInput;
        lastAcceptingState = new RejectState(new List.from(currentState.inputs));
        lastAcceptingInput = null;
        return true;
      }
    }

    // If there's input left to process, process it:
    if (!currentInput.isEmpty) {
      print('more input: ');
      var c = currentInput.first;
      currentState = currentState.next(c);
      currentInput = new List.from(currentInput.skip(1));
    }

    // If more progress could be made, keep working.
    if (!currentInput.isEmpty || !currentState.isReject){
      print('more progress');
      return true;
    }

    // Check again to see if the current state must accept.
    if (currentState.mustAccept) {
      print('mustAccept again');
      currentState = currentState.accept();
      lastAcceptingState = new RejectState(inputs);
      lastAcceptingInput = null;
      return true;
    }
    return false;
  }

  _State emit(token) {
    output.add(token);
    main.inputs = new List();
    return main;
  }
  _State hidden(token) {
    _hidden.add(token);
    main.inputs = new List();    
    return main;
  }
  void terminate(){
    print('DONE .. yay!!');
  }
}

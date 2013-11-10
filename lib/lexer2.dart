library lexer;

import 'dart:async';

part 'src/language.dart';
part 'src/rules.dart';
part 'src/builder.dart';
part 'src/states.dart';


class Token {
  final String value;
  int position;
  Token(this.value);
  toString() => '$runtimeType: $value(${value.length}):$position';

}

abstract class StreamPart {
  /// Input stream where characters are coming in.
  Stream<String> inputStream;

  /// Output stream where tokens are coming out.
  StreamController<Token> outputStream;

  /// Subscription on [inputStream] while subscribed.
  StreamSubscription<String> _subscription;

  init() {
    outputStream = new StreamController<Token>(
      onListen: _onListen,
      onPause: _onPause,
      onResume: _onResume,
      onCancel: _onCancel);
  }

  /// Implements [Stream.listen]
  StreamSubscription<Token> listen(void onData(Token token),
                                    { void onError(Error error),
                                      void onDone(),
                                      bool cancelOnError }) {
    return outputStream.stream.listen(onData,
                                     onError: onError,
                                     onDone: onDone,
                                     cancelOnError: cancelOnError);
  }

  _onListen() {
    _subscription = inputStream.listen(_onData,
                                   onError: outputStream.addError,
                                   onDone: _onDone);
  }
  _onResume() {
    _subscription.pause();
  }
  _onCancel() {
    _subscription.cancel();
    _subscription = null;
  }
  _onPause() {
    _subscription.resume();
  }

  _onData(String ch);
  _onDone();
}

class SwitchStateRule extends Rule {
  LexerState nextState;
  SwitchStateRule(language, [this.nextState]): super(language){
    action = (Lexer _) => _.currentState = nextState;
  }
  switchTo(LexerState state){
    nextState = state;
  }
  SwitchStateRule derive(dynamic ch) =>
      new SwitchStateRule(language.derive(ch), nextState);
}

class LexerState {

  /// Last match if any. Used to match as much input as possible.
  /// Example: kleene star (.*).
  Rule lastMatch;

  /// Rules defined for this state.
  List<Rule> rules = [];

  LexerState _initState;

  LexerState([rules, this.lastMatch, _initState]) {
    if(rules != null) this.rules = rules;
    if(_initState == null){
      this._initState = this;
    } else {
      this._initState = _initState;
    }
  }

  /// Find next state.
  LexerState derive(ch, context){
    if(rules.isEmpty) {
      throw new NoMatch(this);
    }
    if(lastMatch != null){
      return deriveLastMatch(ch, context);
    }
    return deriveRules(ch);
  }

  /// Find next state for all rules.
  LexerState deriveRules(ch) =>
    new LexerState(rules.map((_) => _.derive(ch)).where((_) => !_.isReject),
                   this.lastMatch, this._initState);

  /// Find next state for last match.
  LexerState deriveLastMatch(ch, context){
    var ds = lastMatch.derive(ch);
    if(ds.isMatchable){
      return new LexerState(rules, ds, this._initState);
    }
    //TODO: would this crash if action is trying to change state?
    ds.action(context);
    return _initState.derive(ch, context);
  }

  /// Return list of exact match rules for the current state.
  List<Rule> findExactMatches() => rules.where((_) => _.isMatch);

  /// Return list of possible match rules for the current state.
  List<Rule> findPossibleMatches() => rules.where((_) => _.isMatchable);

  List<Rule> findSwitchStateRules() =>
      findExactMatches().where((_) => _ is SwitchStateRule);

  SwitchStateRule on(language){
    var rule = new SwitchStateRule(toLanguage(language));
    rules.add(rule);
    return rule;
  }
  toString() => '$runtimeType: $rules';
}


class Lexer extends Stream<Token> with StreamPart, Context {
  /// Matching string so far.
  String matchStr = '';

  Lexer(initialState, inputStream){
    this.initialState = initialState;
    this.currentState = initialState;
    this.inputStream = inputStream;
    init();
  }

  //Stream part implementation
  _onData(String ch){
    print("$currentState: '$matchStr'");
    matchStr += ch;
    currentState = currentState.derive(ch, this);

    try {
      exactMatch(this);
      matchable(this);
    } on Continue {}
  }

  _onDone(){
    print(currentState);
  }

  /// Public methods
  emit(token){
    outputStream.add(token);
    currentState = initialState;
    matchStr = '';
  }
}

class Continue {}
class NoMatch {
  final value;
  NoMatch(this.value);
  toString() => "$NoMatch('$value')";
}

void exactMatch(Lexer context){
  if(context.currentState.lastMatch != null) return;
  var matches = context.currentState.findExactMatches();
  if(matches.length > 1) throw "More that one match is not supported yet $matches";
  if(matches.length == 1) {
    matches.first.action(context);
    throw new Continue();
  }
}

void matchable(Lexer context){
  if(context.currentState.lastMatch != null) return;
  var matchables = context.currentState.findPossibleMatches();
  if(matchables.length > 1) throw "More that one matchable not supported yet";
  if(matchables.length == 1) {
    context.currentState.lastMatch = matchables.first;
  }
}

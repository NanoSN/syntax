library lexer;

import 'dart:async';
import 'dart:collection';

part 'src/language.dart';
part 'src/rules.dart';
part 'src/builder.dart';
part 'src/states.dart';
part 'src/debug.dart';

class Token {
  String value;
  int position;
  Token([this.value, this.position]);
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

/** Mixin class to add internal state functionality to a state.
 * TODO: this does not work as a mixin. because of mixin limitation
 *       that it can only apply if class has no constructor.
 *
 *  In this case if we created a class with this as mixin
 *  class Comments extends LexerState with InternalState {}
 *  the compiler will complain:
 *  """forwarding constructors must not have optional parameters
 *  class Comments extends LexerState with InternalState {"""
 *                                         ^
 */
class InternalState {
  int internalState = 0;

  ///TODO: this might be dangerous when ++ += -- -= are used.
  /// It is usually expecting a new object o+1, o+=1.
  operator +(n) => this..internalState += n;
  operator -(n) => this..internalState -= n;
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
    //If we can accept more .. keep going
    var current = deriveRules(ch);
    if(current.findNotRejects().length > 0) return current;

    //TODO: would this crash if action is trying to change state?
    ds.action(context);
    return _initState.derive(ch, context);
  }

  /// Return list of exact match rules for the current state.
  List<Rule> findExactMatches() => rules.where((_) => _.isMatch);

  /// Return list of possible match rules for the current state.
  List<Rule> findPossibleMatches() => rules.where((_) => _.isMatchable);

  /// Return list of possible match rules for the current state.
  List<Rule> findNotRejects() => rules.where((_) => !_.isReject);

  _RuleBuilder on(dynamic language){
    var rule = new _RuleBuilder(language);
    rules.add(rule);
    return rule;
  }

  ///Syntactic sugar
  operator <<(dynamic language) => on(language);
  toString() => '$runtimeType: $rules';
}


class Lexer extends Stream<Token> with StreamPart, Context {

  ///Debugging
  var debug = new Debug();

  /// Matching string so far.
  String matchStr = '';
  int position = 0;
  int get p => position;
  String get m => matchStr;

  LexerState INIT = new LexerState();

  Lexer(inputStream, [initState]){
    if(initState != null) INIT = initState;
    this.initialState = INIT;
    this.currentState = initialState;
    this.inputStream = inputStream;
    init();
  }

  //Stream part implementation
  _onData(String ch){
    if(currentState == null) currentState = initialState;
    try {
      if(DEBUG)
        debug.addTrace(new Trace(ch:ch, state:currentState, matchStr:matchStr));
      currentState = currentState.derive(ch, this);
      matchStr += ch; //This has to be in this order.
      canMatchMore(this);
      exactMatch(this);
      matchable(this);
    } on Continue {
    } on NoMatch catch(e){
      //if(DEBUG) print(debug);
      _subscription.cancel();
      outputStream.addError(e);
    }
  }

  _onDone(){
    if(currentState.lastMatch != null)
      currentState.lastMatch.action(this);

    if(!matchStr.isEmpty) outputStream.addError(new NoMatch(this));
    if(DEBUG) print(debug);
    outputStream.close();
  }

  /// Public methods
  emit(token){
    outputStream.add(token);
    currentState = initialState;
    position+= matchStr.length;
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

void canMatchMore(Lexer context){
  var more = context.currentState.findNotRejects();
  if(more.length > 1){
    var exact = context.currentState.findExactMatches();
    if(exact.length > 0){
      context.currentState.lastMatch = exact.first;
    }
    throw new Continue();
  }
}

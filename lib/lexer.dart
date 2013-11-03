library lexer;

import 'dart:async';

part 'src/language.dart';
part 'src/rules.dart';
part 'src/builder.dart';

class Token {
  final String value;
  int position;
  Token(this.value);
  toString() => '$runtimeType: $value(${value.length}):$position';

}

/// Main entry for lexing.
class Lexer extends Stream<Token> {

  /// Rules defined for lexing.
  final List<Rule> rules;

  /// Input stream where characters are coming in.
  final Stream<String> inputStream;

  /// Output stream where tokens are coming out.
  StreamController<Token> outputStream;

  /// Represents the current state of lexing.
  State state;

  /// Subscription on [inputStream] while subscribed.
  StreamSubscription<String> _subscription;

  /// Position of the current character.
  int position = 0;

  Lexer(this.rules, this.inputStream){
    outputStream = new StreamController<Token>(
      onListen: _onListen,
      onPause: _onPause,
      onResume: _onResume,
      onCancel: _onCancel);

    state = new State(rules, outputStream, position);
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

  void _onData(String ch){
    position ++;

    try{
      state = state.derive(ch);
      new ExactMatch(state).evaluate();
      new Matchable(state).evaluate();

    } on Dispatched {
      state = new State(rules, state.outputStream, position);
    } on LastMatchDispatched {
      state = new State(rules, outputStream, position).derive(ch);
    }
  }
  void _onDone(){state.dispatchLastMatch();}
}


/// Represents a [Transition] in the state machine.
class Transition{}

class Dispatched extends Transition {}
class LastMatchDispatched extends Transition{}

/// Reperesents a [State] in the state machine.
class State {

  /// Matching string so far.
  String matchStr;

  /// Last match if any. Used to match as much input as possible.
  /// Example: kleene star (.*).
  Rule lastMatch;

  /// Rules defined for this state.
  final List<Rule> rules;

  /// Output stream where [Token]s are added to.
  final StreamController<Token> outputStream;

  final int position;


  State(this.rules, this.outputStream, this.position,
        [this.matchStr='', this.lastMatch]);

  /// Find next state.
  State derive(ch){
    if(lastMatch != null){
      return deriveLastMatch(ch);
    }
    return deriveRules(ch);
  }

  /// Find next state for all rules.
  State deriveRules(ch) {
    matchStr += ch;
    return new State(rules.map((_) => _.derive(ch)).where((_) => !_.isReject),
                     outputStream, position, this.matchStr, this.lastMatch);
  }

  /// Find next state for last match.
  State deriveLastMatch(ch){
    var ds = lastMatch.derive(ch);
    if(ds.isMatchable){
      matchStr += ch;
      return new State(rules, outputStream, position, matchStr, ds);
    }
    outputStream.add(ds.action(matchStr)..position = position);
    throw new LastMatchDispatched();
  }

  /// Return list of exact match rules for the current state.
  List<Rule> findExactMatches() => rules.where((_) => _.isMatch);

  /// Return list of possible match rules for the current state.
  List<Rule> findPossibleMatches() => rules.where((_) => _.isMatchable);

  /// Dispatch [Rule.action] to the output stream.
  void dispatch() => outputStream.add(rules.first.action(matchStr)
    ..position=position);

  void dispatchLastMatch() {
    if(lastMatch != null){
      outputStream.add(lastMatch.action(matchStr)..position=position);
    }
  }
}

abstract class Condition {
  final State state;
  Condition(this.state);
  void evaluate();
}

class ExactMatch extends Condition {
  ExactMatch(state): super(state);

  void evaluate(){
    if(state.lastMatch != null) return;
    var matches = state.findExactMatches();
    if(matches.length > 1) throw "More that one match is not supported yet";
    if(matches.length == 1) {
      state.dispatch();
      throw new Dispatched();
    }
  }
}

class Matchable extends Condition {
  Matchable(state): super(state);

  void evaluate(){
    if(state.lastMatch != null) return;
    var matchables = state.findPossibleMatches();
    if(matchables.length > 1) throw "More that one matchable not supported yet";
    if(matchables.length == 1) {
      state.lastMatch = matchables.first;
    }
  }
}

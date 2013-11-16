library lexer;

import 'dart:async';
import 'dart:collection';

part 'src/language.dart';
part 'src/rules.dart';
part 'src/builder.dart';
part 'src/debug.dart';
part 'src/stream.dart';

class Token {
  String value;
  int position;
  Token([this.value, this.position]);
  toString() => '$runtimeType: "$value"(${value.length}):$position';
}

class State {
  List<Rule> rules;
  String matchedInput;
  State([this.matchedInput, this.rules]){
    if(rules == null) rules = <Rule>[];
    if(matchedInput == null) matchedInput = '';
  }

  bool get mustAccept {
    if(rules.isEmpty) return false;
    if(rules.length > 1) return false;
    return rules.first.isMatch;
  }

  bool get canMatchMore => rules.any((_) => !_.isReject);
  bool get hasExactMatch => rules.any((_) => _.isMatch);

  //Not yet used
  bool get hasMatchables => rules.any((_) => _.isMatchable);
  bool get isReject => rules.every((_) => _.isReject);

  State next(String ch, Context context) =>
      new State(matchedInput + ch,
                rules.map((_) => _.derive(ch)).where((_) => !_.isReject));

  State dispatch(Context context){
    var stateLike = rules.first.action(this, context);
    if(stateLike is State) return stateLike;
    return context.initialState;
  }

  _RuleBuilder on(dynamic language){
    var rule = new _RuleBuilder(language);
    rules.add(rule);
    return rule;
  }

  ///Syntactic sugar
  operator / (dynamic language) => on(language);
  toString() => '$runtimeType: $rules, Matched: "$matchedInput"';
}

class RejectState extends State {
  bool get isReject => true;
  State dispatch(Context context) => throw 'Rejecting something is not right.';
}

class Context {
  State initialState;
}

class Lexer extends TokenStream implements Context {
  State INIT = new State();
  State initialState;
  State currentState;
  State lastMatchingState;

  //TODO
  int position = 0;

  final debug = new Debug();
  Lexer(inputStream, [this.initialState]): super(inputStream){
    if (initialState == null) initialState = INIT;
    currentState = initialState;
  }

  void _onData(String ch){
    try{
      currentState = this.next(ch);
    } on NoMatch catch(e){
      _subscription.cancel();
      outputStream.addError(e);
    }
  }

  State next(ch){
    currentState = currentState.next(ch, this);

    if(currentState.hasExactMatch){
      lastMatchingState = currentState;
      return currentState;

    } else {
      if(currentState.canMatchMore){
        lastMatchingState = currentState;
        return currentState;
      }

      if(lastMatchingState != null){
        remainingInput = getRemainingInput(ch);
        // print("currentInput: '${currentState.matchedInput}'");
        // print("LastMatchInput: '${lastMatchingState.matchedInput}'");
        // print("Remaining:    '$remainingInput'");
        currentState = lastMatchingState.dispatch(this);
        lastMatchingState = null;

        // print("|$ch|----- CurrentState Before Recursion: ------");
        // print(currentState);
        // print("----- END  ------\n\n");

        // Recurse over all characters we missed.
        for(final c in remainingInput.split('')){
          // print("'$c'");
          currentState = next(c);
          // print(currentState);
        }
        return currentState;
      }
    }
    throw new NoMatch(currentState);
  }

  var remainingInput;
  String getRemainingInput(ch) =>
      currentState.matchedInput.replaceFirst(lastMatchingState.matchedInput,
                                             '');

  void _onDone(){
    if(lastMatchingState != null) lastMatchingState.dispatch(this);
    outputStream.close();
  }

  /// Public methods
  emit(token){
    outputStream.add(token);
    //currentState = initialState;
    //position+= matchStr.length;
    //matchStr = '';
  }
}

class NoMatch {
  final value;
  NoMatch(this.value);
  toString() => "$NoMatch('$value')";
}

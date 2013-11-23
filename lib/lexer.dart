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
    List exactMatch = rules.where((_) => _.isMatch);
    List matchables = rules.where((_) => _.isMatchable);
    var stateLike;

    if(!exactMatch.isEmpty)
      stateLike = exactMatch.first.action(this, context);
    else if(!matchables.isEmpty)
      stateLike = matchables.first.action(this, context);
    else throw "Something not right here .. should have state,"
               "or state creator function $rules, Matching: $matchedInput";
    if(stateLike is State) return stateLike;

    // At this point the matchedInput has been taken care of so we will
    // just reset it.
    context.top().matchedInput = '';
    return context.top();
    // TODO: Should we respect #on? so sub states can reset and continue
    // push.. pop.. top.. stack behaviour.
    // 'push' every time we switch from state to another
    // 'pop' only when we see EndState() / or a better name
    // 'top' as long as we don't see a push or a pop
    //return context.initialState;
  }

  _RuleBuilder on(dynamic language){
    var rule = new _RuleBuilder(language);
    rules.add(rule);
    return rule;
  }

  ///Syntactic sugar
  operator / (dynamic language) => on(language);
  toString() =>
    '$runtimeType: ${rules.join('\n')},\n Matched: \'$matchedInput\'';
}

class RejectState extends State {
  bool get isReject => true;
  State dispatch(Context context) => throw 'Rejecting something is not right.';
}

class Context {
  State initialState;
  List<State> stack;
}
class Lexer extends TokenStream implements Context {
  State INIT = new State();
  State initialState;
  State currentState;
  State lastMatchingState;
  List<State> stack = <State>[];

  //TODO: make position actually work.
  int position = 0;

  final debug = new Debug();
  Lexer(inputStream, [this.initialState]): super(inputStream){
    if (initialState == null) initialState = INIT;
    currentState = initialState;
  }

  void _onData(String ch){
    try{
      currentState = this.next(ch);
    } catch (e){
      _subscription.cancel();
      outputStream.addError(e);
      outputStream.addError("Error while lexing at position: $position");
      outputStream.addError("Current stack: " + stack.map((_) => _.runtimeType)
        .join(','));
      outputStream.addError("Stack top:${stack.last}");
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

        print("currentInput: '${currentState.matchedInput}'");
        print("LastMatchInput: '${lastMatchingState.matchedInput}'");
        print("Remaining:    '$remainingInput'");
        print("canMatchMore:    '${lastMatchingState.canMatchMore}'");

        currentState = lastMatchingState.dispatch(this);
        lastMatchingState = null;


        // Recurse over all characters we missed.
        for(final c in remainingInput.split('')){
          currentState = next(c);
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
  emit(token, state){
    outputStream.add(token);
    position+= state.matchedInput.length;
    state.matchedInput = '';
  }

  /// Stack operations

  /// Adds [State] to [stack] and returns the pushed [State].
  State push(State state){
    stack.add(state);
    return state;
  }

  /// Removes the top of the [stack] and returns it.
  State pop(){
    if(stack.isEmpty) return initialState;
     stack.removeLast();
    return top();
  }

  /// Returns the top of the stack without removing it.
  State top(){
    if(stack.isEmpty) return initialState;
    return stack.last;
  }
}

class NoMatch {
  final value;
  NoMatch(this.value);
  toString() => "$NoMatch('$value')";
}

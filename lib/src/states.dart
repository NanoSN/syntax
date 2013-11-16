part of lexer;

class _State {
  List<Rule> rules;

  /// Input matched and accepted by these rules.
  String matchedInput;

  /// True if input is matched and no more input can be matched.
  bool mustDispatch;

  /// True if more input can be matched.
  bool hasMatchables;

  /// True if no more input can ever be matched.
  bool isReject;

  /// Consume the next input if it is a match.
  _State next(dynamic input, Context context) {}

  /// Dispatch matched input and reset state.
  State dispatch(Context context){}

  /// Syntactic sugar to simplify how we build our grammer.
  _RuleBuilder on(dynamic language){}
  _RuleBuilder operator / (dynamic language) => on(language);

}

///Context in witch states run.
class Context {
  _State initialState;
  _State currentState;
  _State _lastMatchingState;
}

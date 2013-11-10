part of lexer;

class _Condition<T> extends Object with Function {
  isMet(state) => true;

  // 'call' must return T .. TODO: how to enforce this
}

class _State {
//  List<_Condition> conditions = [];
  _State next(input, context) {
  }
}

///Context in witch states run.
class Context {
  var initialState;
  var currentState;
  next(input) {
    currentState = currentState.next(input, this);
  }
}

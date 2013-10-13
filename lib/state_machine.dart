part of lex;

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
    var accepting = rules.where((_) => _.accepts);
    return (accepting.last).accept(inputs);
  }

  /// Checks to see if any of the rules match the end of input.
  /// returns the lexer state after such a match.
  _State terminate() =>
    new InternalState(inputs, rules.mappedBy((_) =>
            _.deriveEND()).where((_) =>!_.rejects));



  /// Checks to see if any of the rules match the input c.
  /// returns the lexer state after such a match.
  _State next(dynamic input) {
    print('next:inputs: $inputs');
    return new InternalState(inputs..add(input), rules.mappedBy((_) =>
            _.derive(input)).where((_) =>!_.rejects));
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

  list<Rule> _rules = <Rule>[];

  /// Starts with empty rules and input
  State(): super([], []);

  void reset () {
    _rules = <Rule>[];
  }

  //TODO: API for adding rules
}

class StatefullState extends State {
  /// During lexing, the last encountered which accepted.
  _State lastAcceptingState;

  /// During lexing, the input associated with the last accepting state.
  List lastAcceptingInput;

  /// During lexing, the current lexer state.
  _State currentState;

  /// During lexing, the location in the current input.
  List currentInput;

  /// output tokens
  List output = [];

  var main = new State();

  /// Starts the lexer on the given input stream.
  /// The field output will contain a live stream of the lexer output.
  void lex (input) {
    currentState = main;
    currentInput = input.splitChars(); //TODO: check type
    print(currentState);
    work();
  }

  void work(){
    while (workStep()) {};
  }

  bool workStep() {
    //    print(currentState);
    //    print(currentInput);
    print(lastAcceptingInput);
    print('inputs: $inputs');
    // First, check to see if the current state must accept.
    if (currentState.mustAccept) {
      print('mustAccept');
      currentState = currentState.accept();
      lastAcceptingState = new RejectState(inputs);
      lastAcceptingInput = null;
      return true;
    }

    // First, check to see if the curret state accepts or rejects.
    if (currentState.isAccept) {
      print('isAccept');
      lastAcceptingState = currentState;
      lastAcceptingInput = inputs;//currentInput;
    } else if (currentState.isReject) {
      print('isReject');
      // Backtrack to the last accepting state; fail if none.
      currentState = lastAcceptingState.accept();
      currentInput = lastAcceptingInput;
      lastAcceptingState = new RejectState(inputs);
      lastAcceptingInput = null;
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
        lastAcceptingState = new RejectState(inputs);
        lastAcceptingInput = null;
        return true;
      }
    }

    // If there's input left to process, process it:
    if (!currentInput.isEmpty) {
      print('more input');
      var c = currentInput.first;
      currentState = currentState.next(c);
      currentInput = new List.from(currentInput.skip(1));
    }

    // If more progress could be made, keep working.
    if (!currentInput.isEmpty || currentState.isReject){
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
    return main;
  }
  _State hidden(token) {
    output.add(token);
    return main;
  }
}

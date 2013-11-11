part of lexer;

var DEBUG = false;
class Trace {
  var char;
  var state;
  var matchStr;
  Trace({ch:'', state, matchStr}):
      this.char = ch,
      this.state = state,
      this.matchStr = matchStr {}
  toString() => "Char: '$char', State:$state, Match: '$matchStr'";
}

class Debug {
  final Queue<Trace> stacktrace = new Queue<Trace>();
  void addTrace(Trace trace) {
    print(trace);
    stacktrace.addFirst(trace);
  }
  String toString() => stacktrace.join('\n');
}


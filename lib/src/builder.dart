/// Helper functions for building [Language].

part of lexer;


/// Main entry for the builder.
Language rx(List<dynamic> languages){
  var result = toLanguage(languages.first);
  for(int i=1; i< languages.length; i++){
    result = new And(result, toLanguage(languages[i]));
  }
  return result;
}


Language or(List<dynamic> languages){
  var result = toLanguage(languages.first);
  for(int i=1; i< languages.length; i++){
    result = new Or(result, toLanguage(languages[i]));
  }
  return result;
}

Language and(List<dynamic> languages) => rx(languages);
Language oneOrMore(dynamic language) => new And(toLanguage(language),
                                                new Star(toLanguage(language)));
Language zeroOrMore(dynamic language) => new Star(toLanguage(language));
Language zeroOrOne(dynamic language) => new Optional(toLanguage(language));
Language optional(dynamic language) => zeroOrOne(language);

Language exactly(dynamic language, {int times:1}){
  language = toLanguage(language);
  var result = language;
  for(int i = 1; i < times; i++){
    result = new And(result, language);
  }
  return result;
}


/// Try to convert anything to [Language].
Language toLanguage(dynamic thing){
  if(thing is String) return word(thing);
  if(thing is Language) return thing;
  if(thing is Rule) return thing.language;
  throw 'Unknown type of language: [$thing] was [${thing.runtimeType}]';
}


/// Converts a [String] into a [Language].
Language word(String str){
  if(str.length == 0) throw 'String is empty.';
  if(str.length == 1) return new Character(str);
  var result = new Character(str[0]);
  for(int i=1; i< str.length; i++){
    result = new And(result, new Character(str[i]));
  }
  return result;
}

Language LETTER = new Letter();
Language DIGIT = new Digit();
Language NEWLINE = new Newline();
Language HEX_DIGIT = new HexDigit();
Language not(dynamic thing) => new Not(toLanguage(thing));
Language notChar(String char) => new NotCharacter(char);


typedef Token TokenCreator();
typedef State StateCreator();

typedef State ForwardCall(State, Lexer);

class _RuleBuilder extends Rule {
  _RuleBuilder(dynamic thing): super(toLanguage(thing));

  void switchTo(dynamic stateLike){
    action = (State state, Lexer lexer) {
      if(stateLike is StateCreator) {
        return stateLike()..matchedInput = state.matchedInput;
      }
      else if (stateLike is State) {
        return stateLike..matchedInput = state.matchedInput;
      }
      else if (stateLike is ForwardCall){
        return stateLike(state, lexer)..matchedInput = state.matchedInput;
      }
      else throw 'I dont know. its not a State!!!';
    };
  }
  void emit(TokenCreator creator) {
    action = (State state, Lexer lexer) {
      var token = creator();
      token.value = state.matchedInput;
      token.position = lexer.position;
      lexer.emit(token, state);
    };
  }

  void call(Action act){
    action = (State state, Lexer lexer){
      var next = act(state, lexer);
      next.matchedInput = state.matchedInput;
      return next;
    };
  }

  /// Helper
  State _toState(dynamic stateLike, State state, Lexer lexer){
    if(stateLike is StateCreator) {
      return stateLike()..matchedInput = state.matchedInput;
    }
    else if (stateLike is State) {
      return stateLike..matchedInput = state.matchedInput;
    }
    else if (stateLike is ForwardCall){
      return stateLike(state, lexer)..matchedInput = state.matchedInput;
    }
    else throw 'I dont know. its not a State!!!';
  }

  void push(dynamic stateLike){
    action = (State state, Lexer lexer) =>
        lexer.push(_toState(stateLike, state, lexer));
  }

  void pop(){
    action = (State state, Lexer lexer) => lexer.pop();
  }

  operator / (TokenCreator creator) => emit(creator);

  /// No pushing or poping here. Just 'do what I say'.
  operator <= (dynamic stateLike) => switchTo(stateLike);

  /// push .. left shift.
  operator << (dynamic stateLike) => push(stateLike);

  /// pop .. right shift (reduce).
  operator >> (dynamic nothing) => pop();
}

/// Marker to be passed to '>>' operator.
var PREVIOUS_STATE = null;

part of syntax;

/// Main entry for the builder.
p.Parser sx(List<dynamic> parsers){
  var result = toParser(parsers.first);
  for(int i=1; i< parsers.length; i++){
    result = p.makeAnd(result, toParser(parsers[i]));
  }
  return result;
}


p.Parser or(List<dynamic> parsers){
  var result = toParser(parsers.first);
  for(int i=1; i< parsers.length; i++){
    result = p.makeOr(result, toParser(parsers[i]));
  }
  return result;
}

p.Parser and(List<dynamic> parsers) => px(parsers);
p.Parser oneOrMore(dynamic parser) => p.makeAnd(toParser(parser),
    p.makeStar(toParser(parser)));
p.Parser zeroOrMore(dynamic parser) => p.makeStar(toParser(parser));
p.Parser zeroOrOne(dynamic parser) => p.makeOptional(toParser(parser));
p.Parser optional(dynamic parser) => zeroOrOne(parser);

List<String> _inCall = <String>[];
var functions_trace = [];
var lex_rules = [];

/// Try to convert anything to [Parser].
p.Parser toParser(dynamic thing, [name]){
  bool hasName = (name != null);
  if(thing is Function){
    var name = reflect(thing).function.simpleName.toString();
    functions_trace.add(name);

    return functionToParser(thing, name);
  }

  // Terminal, add lexer rule.
  if(thing is String) {
    lex_rules.add(thing);
    return new p.TokenParser(new p.TokenDefinition(value:thing),
                             hasName? name : thing);
  }
  if(thing is p.Parser) return thing;

  // Terminal, add lexer rule.
  if(thing is l.Rule) {
    lex_rules.add(thing);
    return new p.TokenParser(new p.TokenDefinition(type:thing.token),
                             hasName? name : '${thing.runtimeType}');
  }

  // Not too sure what to do about this one .. need more examples.
  // if(thing is Token) return new p.TokenParser(new p.TokenDefinition(type:thing),
  //                                           hasName? name : '${thing.runtimeType}');
  throw 'Unable to convert type known [${thing.runtimeType}] to Parser';
}



p.Parser functionToParser(Function fn, name){
  if(_inCall.contains('$name')){
    var thing = p.cache['$name'];
    return new p.Lazy(thing, name);
  }
  else _inCall.add('$name');
  return p.cache.putIfAbsent('$name', () => toParser(fn(), name));
}


class LanguageRuleBuilder extends l.Rule {
  LanguageRuleBuilder(dynamic thing): super(l.toLanguage(thing));
  Token get token => _creator();
  l.TokenCreator _creator;
  void emit(l.TokenCreator creator) {
    _creator = creator;
    action = (l.State state, l.Lexer lexer) {
      var token = creator();
      token.value = state.matchedInput;
      token.position = lexer.position;
      lexer.emit(token, state);
    };
    return this;
  }
  operator <= (l.TokenCreator creator) => emit(creator);
}

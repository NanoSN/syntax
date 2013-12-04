/// Parser Expression builder.

part of parser;

/// Main entry for the builder.
Parser px(List<dynamic> parsers){
  var result = toParser(parsers.first);
  for(int i=1; i< parsers.length; i++){
    result = makeAnd(result, toParser(parsers[i]));
  }
  return result;
}


Parser or(List<dynamic> parsers){
  var result = toParser(parsers.first);
  for(int i=1; i< parsers.length; i++){
    result = makeOr(result, toParser(parsers[i]));
  }
  return result;
}

Parser and(List<dynamic> parsers) => px(parsers);
Parser oneOrMore(dynamic parser) => makeAnd(toParser(parser),
    makeStar(toParser(parser)));
Parser zeroOrMore(dynamic parser) => makeStar(toParser(parser));
Parser zeroOrOne(dynamic parser) => makeOptional(toParser(parser));
Parser optional(dynamic parser) => zeroOrOne(parser);


Map<String, Parser> cache = <String,Parser>{};
List<String> _inCall = <String>[];
/// Try to convert anything to [Parser].
Parser toParser(dynamic thing){
  if(thing is Function) return functionToParser(thing);
  if(thing is String) return new TokenParser(new TokenDefinition(value:thing));
  if(thing is Parser) return thing;
  if(thing is Token) return new TokenParser(new TokenDefinition(type:thing));
  throw 'Unable to convert type known [${thing.runtimeType}] to Parser';
}

Parser functionToParser(Function fn){
  if(_inCall.contains('$fn')){
    var thing = cache['$fn'];
    return new Lazy(thing, '$fn');
  }
  else _inCall.add('$fn');
  return cache.putIfAbsent('$fn', () => toParser(fn()));
}
